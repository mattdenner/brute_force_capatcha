require 'spec_helper'

class LiveSetsUS::Processor
  attr_accessor :url_queue
  attr_accessor :headers
  expose(:protected)
end

describe LiveSetsUS::Processor do
  before(:each) do
    @processor = described_class.new
  end
  
  describe '#initialize' do
    it 'should create an empty URL queue' do
      @processor.url_queue.should be_empty
    end
  end

  describe '#push' do
    it 'should append the URL to the end of the list' do
      @processor.url_queue = [ 'url1' ]
      @processor.push('url2')
      @processor.url_queue.should == [ 'url1', 'url2' ]
    end
  end

  describe '#open_http_connection' do
    describe 'with request modification' do
      before(:each) do
        FakeWeb.register_uri(:get, 'http://some.url/', :body => 'foo')
        
        @request = Net::HTTP::Get.new('/')
        Net::HTTP::Get.should_receive(:new).and_return(@request)
      end

      it 'should copy any headers into the request' do
        @request.should_receive(:initialize_http_header).with('Cookie' => 'cookie')
        @processor.headers[ 'Cookie' ] = 'cookie'
        @processor.open_http_connection('http://some.url/').body.should == 'foo'
      end

      it 'should allow you to modify the request' do
        receiver = mock('block')
        receiver.should_receive(:received).with(@request)
        
        @processor.open_http_connection('http://some.url/') do |request|
          receiver.received(request)
        end.body.should == 'foo'
      end
    end

    it 'should copy the cookie header from the response' do
      FakeWeb.register_uri(:get, 'http://some.url/', :body => 'foo', :set_cookie => 'cookie;dough')

      @processor.open_http_connection('http://some.url/').body.should == 'foo'
      @processor.headers[ 'Cookie' ].should == 'cookie'
    end

    it 'should allow you to change the request class' do
      FakeWeb.register_uri(:post, 'http://some.url/', :body => 'foo')
      @processor.open_http_connection('http://some.url/', Net::HTTP::Post).body.should == 'foo'
    end
  end

  describe '#handler_for' do
    it 'should extract the capatcha' do
      doc = Nokogiri::HTML('<html><body><form id="frmLogin"><input name="ver5" value="capatcha id"/></form></body></html>')

      @processor.should_receive(:handle).with('uri', 'capatcha id', 'path').and_return(:ok)
      @processor.handler_for('path').call('uri', doc).should == :ok
    end
  end

  describe '#process_urls_to' do
    before(:each) do
      @path, @path_exists = 'some/nested/path', true
      @processor.should_receive(:process).with(any_args).and_return(:ok)
      @processor.should_receive(:handler_for).with(@path).and_return(proc { |_| })
    end

    after(:each) do
      File.should_receive(:directory?).with(@path).and_return(@path_exists)
      @processor.process_urls_to(@path).should == :ok
    end

    it 'should create the path if it does not exist' do
      @path_exists = false
      FileUtils.should_receive(:mkdir_p).with(@path)
    end

    it 'should not create the path if it exists' do
      # Do nothing, should be ok
    end
  end

  describe '#content_for' do
    before(:each) do
      @source_url, @destination = 'http://source.url/', 'destination'
    end
    
    it 'should retrieve the content' do
      FakeWeb.register_uri(:get, @source_url, :body => 'content')
      @processor.content_for(@source_url).should == 'content'
    end
  end

  describe '#process' do
    it 'should error if the URL queue is empty' do
      lambda { @processor.process }.should raise_error(StandardError)
    end

    def capatcha_page(capatcha_id)
      <<-END_OF_PAGE
        <html>
          <body>
            <form id="frmLogin">
              <input name="ver5" value="#{ capatcha_id }"/>
            </form>
          </body>
        </html>
      END_OF_PAGE
    end

    it 'should yield the document' do
      source_url, content = 'http://source.url/', capatcha_page('capatcha id')
      
      handler = mock('handler')
      handler.should_receive(:call).with(source_url, an_instance_of(Nokogiri::HTML::Document))
      
      FakeWeb.register_uri(:get, source_url, :body => content)
      
      @processor.push(source_url)
      @processor.process { |*args| handler.call(*args) }
      @processor.url_queue.should be_empty
    end
  end
end
