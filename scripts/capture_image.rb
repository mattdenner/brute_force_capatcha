#!/usr/bin/ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fileutils'

url = ARGV.first or raise 'Usage: capture_image <URL>'

$stderr.puts "Downloading '#{ url }' ..."
doc = Nokogiri::HTML(open(url))

FileUtils.mkdir_p('downloads/capatchas') unless File.directory('downloads/capatchas')

$stderr.puts "Extracting capatcha ..."
doc.xpath('//form[@id="frmLogin"]//input[@name="ver5"]').each do |node|
  capatcha_code = node.attribute('value').to_s
  filename = "downloads/capatchas/#{ capatcha_code }.jpg"
  File.open(filename, 'wb') do |file|
    file.write(open("http://www.livesets.us/vimages/#{ capatcha_code }.jpg").read)

    $stderr.puts "\tCode: #{ capatcha_code }"
  end unless File.exists?(filename)
end

$stderr.puts "Done"
