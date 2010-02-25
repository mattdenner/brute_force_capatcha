require 'net/http'
require 'nokogiri'

module LiveSetsUS #:nodoc:
  class Processor
    attr_reader :url_queue
    delegate :push, :to => :url_queue

    def initialize
      @url_queue, @headers = [], {}
    end

    def process_urls_to(path)
      FileUtils.mkdir_p(path) unless File.directory?(path)
      process(&handler_for(path))
    end

    protected
    
    def handler_for(path)
      proc { |uri,capatcha_id| handle(uri, capatcha_id, path) }
    end

    def process
      raise StandardError, 'No URLs to processor' if self.url_queue.empty?
      self.url_queue.each do |uri|
        doc = Nokogiri::HTML(content_for(uri))
        yield(uri, doc.xpath('//form[@id="frmLogin"]//input[@name="ver5"]').first.attribute('value').to_s)
      end
    end

    def content_for(uri)
      open_http_connection(uri).body
    end

    def open_http_connection(uri, request_class = Net::HTTP::Get)
      url = URI.parse(uri)
      Net::HTTP.start(url.host, url.port) do |http|
        request = request_class.new(url.path)
        @headers.each { |header,value| request[ header ] = value }
        yield(request) if block_given?

        response = http.request(request)
        store_header(response, 'Set-Cookie', 'Cookie') { |value| value.sub(/;.+$/, '') }
        response
      end
    end

    def store_header(response, response_header, request_header)
      value = original_value = response[ response_header ]
      return if original_value.nil?
      value = yield(value) if block_given?
      @headers[ request_header ] = value
    end

    def capatcha_image_for_processing(capatcha_id)
      image = MiniMagick::Image.from_blob(
        content_for("http://www.livesets.us/vimages/#{ capatcha_id }.jpg"), 
        'jpg'
      )
      image.combine_options do |steps|
        steps.colorSpace('Gray')
        steps.normalize
        steps.crop('18x12+2+10')
      end
      image
    end
  end
end

