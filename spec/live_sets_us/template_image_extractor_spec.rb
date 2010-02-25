require 'spec_helper'

class LiveSetsUS::TemplateImageExtractor
  expose(:private)
end

describe LiveSetsUS::TemplateImageExtractor do
  before(:each) do
    @extractor = described_class.new
  end

  describe '#extract_to' do
    before(:each) do
      @path, @path_exists = 'some/nested/path', true
      @extractor.should_receive(:process).with(any_args).and_return(:ok)
    end

    after(:each) do
      File.should_receive(:directory?).with(@path).and_return(@path_exists)
      @extractor.extract_to(@path).should == :ok
    end
    

    it 'should create the path if it does not exist' do
      @path_exists = false
      FileUtils.should_receive(:mkdir_p).with(@path)
    end

    it 'should not create the path if it exists' do
      # Do nothing, should be ok
    end
  end

  describe '#handler_for' do
    it 'should pass the path to the handle method' do
      @extractor.should_receive(:handle).with('capatcha id', 'path').and_return(:ok)
      @extractor.handler_for('path').call('capatcha id').should == :ok
    end
  end

  describe '#handle' do
    def read_image(image)
      File.open(File.expand_path(File.join(File.dirname(__FILE__), '..', 'images', "#{ image }.jpg")), 'rb') do |file|
        file.read
      end
    end

    def test_image_content(capatcha_id)
      read_image(capatcha_id)
    end

    def template_image_content(capatcha_id, side)
      read_image("#{ capatcha_id }-#{ side }")
    end

    before(:each) do
      @capatcha_id = 'capatcha1'
    end

    after(:each) do
      [ :left, :right ].each { |s| File.unlink(File.join('/tmp', "#{ @capatcha_id }-#{ s }.jpg")) }
    end

    it 'should process the image' do
      @extractor.should_receive(:content_for).with("http://www.livesets.us/vimages/#{ @capatcha_id }.jpg").and_return(test_image_content(@capatcha_id))
      @extractor.handle(@capatcha_id, '/tmp')

      [ :left, :right ].each do |s|
        File.open("/tmp/#{ @capatcha_id }-#{ s }.jpg", 'rb') do |file|
          file.read
        end.should == template_image_content(@capatcha_id, s)
      end
    end
  end
end
