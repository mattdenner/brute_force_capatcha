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

  describe 'download functionality' do
    before(:each) do
      @source_url, @destination = 'http://source.url/', 'destination'
    end

    describe '#content_for' do
      it 'should retrieve the content' do
        FakeWeb.register_uri(:get, @source_url, :body => 'content')
        @processor.content_for(@source_url).should == 'content'
      end
    end
 
    describe '#download_with_net_http' do
      it 'should write the downloaded file' do
        FakeWeb.register_uri(:get, @source_url, :body => 'content')
        
        file = mock('file')
        file.should_receive(:write).with('content')
        File.should_receive(:open).with(@destination, 'wb').and_yield(file)
        
        @processor.download_with_net_http(@source_url, @destination)
      end
    end

    describe '#download_with_axel' do
      it 'should execute the appropriate command' do
        @processor.should_receive(:system).with("axel -n 3 --output='#{ @destination }' '#{ @source_url }'").and_return(:ok)
        @processor.download_with_axel(@source_url, @destination).should == :ok
      end
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
        handler = mock('handler')
        handler.should_receive(:call).with(capatcha_id)
        
        source_url = 'http://source.url/'
        FakeWeb.register_uri(:get, source_url, :body => capatcha_page(capatcha_id))
        
        @processor.push(source_url)
        @processor.process { |a| handler.call(a) }
      end
    end
    it_should_yield_the_capatcha_id('capatcha id 1')
    it_should_yield_the_capatcha_id('capatcha id 2')
  end
end
