require 'spec_helper'

class LiveSetsUS::TemplateImageExtractor
  expose(:private)
end

describe LiveSetsUS::TemplateImageExtractor do
  before(:each) do
    @extractor = described_class.new
  end

  describe '#handler_for' do
    it 'should pass the path to the handle method' do
      @extractor.should_receive(:handle).with('uri', 'capatcha id', 'path').and_return(:ok)
      @extractor.handler_for('path').call('uri', 'capatcha id').should == :ok
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
      @extractor.handle('uri', @capatcha_id, '/tmp')

      [ :left, :right ].each do |s|
        File.open("/tmp/#{ @capatcha_id }-#{ s }.jpg", 'rb') do |file|
          file.read
        end.should == template_image_content(@capatcha_id, s)
      end
    end
  end
end
