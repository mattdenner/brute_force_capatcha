module LiveSetsUS
  class TemplateImageExtractor < Processor
    alias_method(:extract_to, :process_urls_to)

    private

    def handle(uri, capatcha_id, destination_path)
      image = capatcha_image_for_processing(capatcha_id)
      { :left => '+0+0', :right => '+9+0' }.each do |side,offset|
        side_image = MiniMagick::Image.from_blob(image.to_blob, 'jpg')
        side_image.crop("9x12#{ offset }")
        side_image.write(File.join(destination_path, "#{ capatcha_id }-#{ side }.jpg"))
      end
    end
  end
end
