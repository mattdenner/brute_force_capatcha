# Contains code dealing with the livesets.us website.
module LiveSetsUS #:nodoc:
  # Downloads the MP3 files after bypassing the capatcha.
  class ContentDownloader < Processor
    # Simple class to hold multiple template images and the logic to correlate them with
    # a given test image.
    class CharacterTemplates #:nodoc:
      CHARACTER_RANGE = ('a'..'z').to_a + ('0'..'9').to_a

      def initialize
        @characters_to_images = CHARACTER_RANGE.inject({}) do |map,character|
          yield(map, character)
          map
        end
        raise StandardError, 'There appear to be no template images' if @characters_to_images.empty?
      end

      def correlate_with(*args)
        @characters_to_images.map do |character,template|
          [ character, template.correlate_with(*args) ]
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

    def initialize(template_image_path, tries = 5)
      super()
      @tries, @template_images = tries, self.class.initialize_template_images_from(template_image_path)
    end

    private

    def handle(uri, capatcha_id, path)
      info("Processing #{ uri } ...")

      link = retrieve_download_link(uri, capatcha_id)
      download_large_file(link[ 0 ], File.join(path, link[ 1 ]))
    end

    def retrieve_download_link(uri, capatcha_id)
      @tries.times do |try|
        debug("Attempt #{ try } for #{ uri } ...")

        code = guess_capatcha_code_in(capatcha_image_for_processing(capatcha_id))
        
        doc = Nokogiri::HTML(open_http_connection(uri, Net::HTTP::Post) do |request|
          request[ 'Referer' ] = uri
          request.form_data = {
            'txtNumber' => code, 
            'ver5' => capatcha_id, 
            'btnLogin' => 'ok' 
          }
        end.body)

        # Try to find the link directly, but if that doesn't exist then we need to find the
        # Javascript and try processing that.
        link = doc.xpath('//*[@id="downloadpane"]//a').first
        return [ link.attribute('href').to_s, link.content.to_s ] unless link.nil?

        code = doc.xpath('//*[@id="downloadpane"]//script[@language="Javascript"]').first
        next if code.nil?

        match = code.content.match(/<a href="([^"]+\.mp3)">([^<]+)<\/a>/i)
        return [ match[ 1 ], match[ 2 ] ] unless match.nil?
      end
      raise StandardError, "Unable to guess the capatcha for '#{ uri }'"
    end

    def download_large_file(source_uri, destination)
      system("axel -n 3 -a -o '#{ destination }' '#{ source_uri }'")
    end

    def guess_capatcha_code_in(image)
      # Build two separate, ordered, lists that contain the likelihoods of each character appearing.
      left_scores, right_scores = {}, {}
      @template_images.correlate_with(image, [ 0, 9 ]).each do |(character,correlation)|
        left_scores[ character ] = correlation[ 0 ]
        right_scores[ character ] = correlation[ 9 ]
      end
      left_scores = left_scores.to_a.sort { |(_,left),(_,right)| left <=> right }
      right_scores = right_scores.to_a.sort { |(_,left),(_,right)| left <=> right }
      
      debug("Left correlations:  #{ left_scores.inspect }")
      debug("Right correlations: #{ right_scores.inspect }")

      [ left_scores.first, right_scores.first ].map { |character,_| character }.join.upcase
    end
  end
end
