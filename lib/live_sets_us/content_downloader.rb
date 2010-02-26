module LiveSetsUS #:nodoc:
  # Downloads the MP3 files after bypassing the capatcha.
  class ContentDownloader < Processor
    # Simple class to hold multiple template images and the logic to correlate them with
    # a given test image.
    class CharacterTemplates #:nodoc:
      def initialize
        @characters_to_images = (('a'..'z').to_a + ('0'..'9').to_a).inject({}) do |map,character|
          yield(map, character)
          map
        end
        raise StandardError, 'There appear to be no template images' if @characters_to_images.empty?
      end

      def correlate_with(image)
        @characters_to_images.inject({}) do |scores,(character,template)|
          scores[ character ] = template.correlate_with(image)
          scores
        end.to_a.sort do |left,right|
          compare = right.last <=> left.last
          compare = left.first <=> right.first if compare == 0
          compare
        end
      end
    end

    class << self
      def initialize_template_images_from(template_image_path) #:nodoc:
        CharacterTemplates.new do |store,character|
          filename = File.expand_path(File.join(template_image_path, "#{ character }.jpg"))
          store[ character ] = MiniMagick::Image.from_file(filename) if File.exists?(filename)
        end
      end
    end

    alias_method(:download_to, :process_urls_to)

    def initialize(template_image_path, tries)
      super()
      @tries, @template_images = tries, self.class.initialize_template_images_from(template_image_path)
    end

    private

    def handle(uri, capatcha_id, path)
      link = nil
      (1..@tries).each do |try|
        code = guess_capatcha_code_in(capatcha_image_for_processing(capatcha_id))

        url = URI.parse(uri)
        content = open_http_connection(uri, Net::HTTP::Post) do |request|
          request.form_data = {
            'txtNumber' => code, 
            'ver5' => capatcha_id, 
            'btnLogin' => 'ok' 
          }
        end.body
        
        link = Nokogiri::HTML(content).xpath('//*[@id="downloadpane"]/a').first
        break unless link.nil?
      end
      raise StandardError, "Unable to guess the capatcha for '#{ uri }'" if link.nil?
      
      download_large_file(
        link.attribute('href').to_s,
        File.join(path, link.content.to_s)
      )
    end

    def download_large_file(source_uri, destination)
      system("axel -n 3 -a -o '#{ destination }' '#{ source_uri }'")
    end

    def guess_capatcha_code_in(image)
      @template_images.correlate_with(image).slice(0, 2).sort do |(_,left),(_,right)| 
        left.x <=> right.x 
      end.map do |correlation,_| 
        correlation
      end.join.upcase
    end
  end
end
