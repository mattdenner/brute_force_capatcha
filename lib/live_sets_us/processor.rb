require 'net/http'
require 'nokogiri'

# Extensions to the Array class
class Array #:nodoc:
  def each_with_action(action = :shift)
    while !self.empty?
      yield(self.send(action))
    end
  end
end

# Extensions to the Net::HTTPHeader module
module Net::HTTPHeader #:nodoc:
  def map_header(response_header)
    value = self[ response_header ]
    yield(value) unless value.nil?
  end
end

# Extensions to the MiniMagic::Image class
class MiniMagick::Image #:nodoc:
  def extract_capatcha
    combine_options do |steps|
      steps.colorSpace('Gray')
      steps.normalize
      steps.crop('18x12+2+10')
    end
    self
  end
end

# Contains code dealing with the livesets.us website.
module LiveSetsUS #:nodoc:
  # Base class for all classes dealing with the interaction with livesets.us capatchas.
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
      proc do |uri,doc|
        handle(
          uri, 
          doc.xpath('//form[@id="frmLogin"]//input[@name="ver5"]').first.attribute('value').to_s,
          path
        )
      end
    end

    def process
      raise StandardError, 'No URLs to processor' if self.url_queue.empty?
      self.url_queue.each_with_action do |uri|
        yield(uri, Nokogiri::HTML(content_for(uri)))
      end
    end

    def content_for(uri)
      open_http_connection(uri).body
    end

    def open_http_connection(uri, request_class = Net::HTTP::Get)
      url = URI.parse(uri)
      Net::HTTP.start(url.host, url.port) do |http|
        request = request_class.new(url.path)
        request.initialize_http_header(@headers)
        yield(request) if block_given?

        response = http.request(request)
        response.map_header('Set-Cookie') do |value| 
          @headers[ 'Cookie' ] = value.sub(/;.+$/, '')
        end
        response
      end
    end

    def capatcha_image_for_processing(capatcha_id)
      MiniMagick::Image.from_blob(
        content_for("http://www.livesets.us/vimages/#{ capatcha_id }.jpg"), 
        'jpg'
      ).extract_capatcha
    end
  end
end

