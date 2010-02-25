require 'mini_magick'

module LiveSetsUS
  class TemplateImageExtractor < Processor
    def extract_to(path)
      FileUtils.mkdir_p(path) unless File.directory?(path)
      process(&handler_for(path))
    end

    private

    def handler_for(path)
      proc { |capatcha_id| handle(capatcha_id, path) }
    end
    
    def handle(capatcha_id, destination_path)
      image = MiniMagick::Image.from_blob(
        content_for("http://www.livesets.us/vimages/#{ capatcha_id }.jpg"), 
        'jpg'
      )
      image.combine_options do |steps|
        steps.colorSpace('Gray')
        steps.normalize
        steps.crop('18x12+2+10')
      end

      { :left => '+0+0', :right => '+9+0' }.each do |side,offset|
        side_image = MiniMagick::Image.from_blob(image.to_blob, 'jpg')
        side_image.crop("9x12#{ offset }")
        side_image.write(File.join(destination_path, "#{ capatcha_id }-#{ side }.jpg"))
      end
    end
  end
end
