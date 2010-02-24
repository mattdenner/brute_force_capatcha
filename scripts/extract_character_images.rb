#!/usr/bin/ruby
require 'rubygems'
require 'mini_magick'
require 'fileutils'

$stderr.puts 'Generating character templates from capatchas ...'

FileUtils.mkdir_p('downloads/characters') unless File.directory?('downloads/characters')

Dir.glob('downloads/capatchas/*.jpg') do |filename|
  capatcha = filename.match(/\/([0-9a-z]+)\.jpg$/i)[ 1 ]

  $stderr.puts "\tProcessing '#{ capatcha }' ..."

  image = MiniMagick::Image.from_file(filename)
  image.combine_options do |steps|
    steps.colorSpace('Gray')
    steps.normalize
    steps.crop('18x12+2+10')
  end

  # Split the image into two sides.  The position of a given letter in either side should be
  # identical, i.e. if we had two A's then you should not be able to distinguish which came
  # from which side.
  { :left => '+0+0', :right => '+9+0' }.each do |side,offset|
    side_image = MiniMagick::Image.from_blob(image.to_blob, 'jpg')
    side_image.crop("9x12#{ offset }")
    side_image.write("downloads/characters/#{ capatcha }-#{ side }.jpg")
  end
end

$stderr.puts 'Done'
