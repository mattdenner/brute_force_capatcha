require 'spec_helper'

describe MiniMagick::Image do
  describe '#correlate_with' do
    def read_image(image)
      described_class.from_file(File.expand_path(File.join(File.dirname(__FILE__), '..', 'images', "#{ image }.jpg")))
    end
    
    def test_image(capatcha_id)
      read_image(capatcha_id)
    end
    
    def template_image(capatcha_id, side)
      read_image("#{ capatcha_id }-#{ side }")
    end

    def self.it_should_deal_with_real_world_images(capatcha)
      it "should work on the real capatcha image #{ capatcha }" do
        test_image = test_image(capatcha).extract_capatcha
        yield.each do |image,expected|
          correlation = template_image(*image).correlate_with(test_image)
          expected.each { |v,i| correlation[ i ].should == v }
        end
      end
    end

    it_should_deal_with_real_world_images('capatcha1') do
      {
        [ 'capatcha1', :left ]  => [   155,  8654, 15095, 12549,  9737, 9774, 10183,  9942, 10198 ].each_with_index,
        [ 'capatcha1', :right ] => [ 11178, 10711, 11478, 11182, 10020, 9861, 11786, 12919,  7699 ].each_with_index
      }
    end
  end
end
