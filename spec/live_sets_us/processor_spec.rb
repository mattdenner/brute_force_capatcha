require 'spec_helper'

class LiveSetsUS::Processor
  attr_accessor :url_queue
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

    def self.it_should_yield_the_capatcha_id(capatcha_id)
      it "should yield the capatcha ID (#{ capatcha_id })" do
        source_url = 'http://source.url/'

        handler = mock('handler')
        handler.should_receive(:call).with(source_url, capatcha_id)
        
        FakeWeb.register_uri(:get, source_url, :body => capatcha_page(capatcha_id))
        
        @processor.push(source_url)
        @processor.process { |*args| handler.call(*args) }
      end
    end
    it_should_yield_the_capatcha_id('capatcha id 1')
    it_should_yield_the_capatcha_id('capatcha id 2')
  end
end
