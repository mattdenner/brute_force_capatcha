module LiveSetsUS
  class ContentDownloader < Processor
    alias_method(:download_to, :process_urls_to)

    def initialize(template_image_path, tries)
      super()
      @template_image_path, @tries = template_image_path, tries
    end

    private
    
    def handler_for(path)
      proc { |uri,capatcha_id| handle(uri, capatcha_id, path) }
    end

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
      character_scored = (('a'..'z').to_a + ('0'..'9').to_a).inject({}) do |h,l|
        correlation_for(l, image) { |template_image| h[ l ] = template_image }
        h
      end.to_a.sort do |a,b|
        compare = b.last <=> a.last
        compare = a.first <=> b.first if compare == 0
        compare
      end

      raise StandardError, 'There appear to be no correlations at all!' if character_scored.empty?

      [ 
        character_scored[ 0 ], 
        character_scored[ 1 ]
      ].sort { |(_,c1),(_,c2)| c1.x <=> c2.x }.map { |c,_| c }.join.upcase
    end

    def correlation_for(character, target_image)
      character_filename = File.expand_path(File.join(@template_image_path, "#{ character }.jpg"))
      yield(MiniMagick::Image.from_file(character_filename).correlate_with(target_image)) if File.exists?(character_filename)
    end
  end
end