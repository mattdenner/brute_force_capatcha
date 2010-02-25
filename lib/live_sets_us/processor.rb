require 'net/http'
require 'nokogiri'

module LiveSetsUS
  class Processor
    attr_reader :url_queue
    delegate :push, :to => :url_queue

    def initialize
      @url_queue = []
    end

    protected

    def process
      raise StandardError, 'No URLs to processor' if self.url_queue.empty?
      self.url_queue.each do |uri|
        doc = Nokogiri::HTML(content_for(uri))
        yield(doc.xpath('//form[@id="frmLogin"]//input[@name="ver5"]').first.attribute('value').to_s)
      end
    end

    def content_for(uri)
      Net::HTTP.get(URI.parse(uri))
    end

    def download(source_uri, destination, type = :net_http)
      send("download_with_#{ type }", source_uri, destination)
    end

    def download_with_net_http(source_uri, destination)
      File.open(destination, 'wb') { |file| file.write(content_for(source_uri)) }
    end

    def download_with_axel(source_uri, destination)
      system("axel -n 3 --output='#{ destination }' '#{ source_uri }'")
    end
  end
end

