#!/usr/bin/ruby
require 'rubygems'
require 'mini_magick'

module MiniMagick
  class RawImage
    class Correlation
      attr_reader :x, :y, :likelihood

      def initialize(x, y, likelihood, likelihoods = nil)
        @x, @y, @likelihood, @likelihoods = x, y, likelihood, likelihoods
      end

      def <=>(correlation)
        correlation.likelihood <=> self.likelihood
      end

      def inspect
        "(#{ self.x },#{ self.y })[#{ self.likelihood }]" << " = #{ @likelihoods.inspect }"
      end
    end

    attr_reader :width, :height

    def initialize(width, height, bytes)
      @width, @height, @bytes = width, height, bytes
    end

    def correlate_with(image)
      correlations = [ 0, 9 ].inject([]) do |a,ic|
        a << [
          (0...self.height).inject(0) do |v1,tr|
            (0...self.width).inject(v1) do |v2,tc|
              v2 + (image.at(ic + tc, tr) - self.at(tc, tr)).abs
            end
          end,
          ic
        ]
      end

      correlation, correlation_x = correlations.sort { |a,b| a.first <=> b.first }.first
      Correlation.new(correlation_x, 0, correlation, correlations)
    end
    
    def at(x, y)
      @bytes[ (y * self.width) + x ] or raise "(#{ x },#{ y }) = #{ self.inspect }"
    end

    def inspect
      "RawImage(#{ @width }x#{ @height }, #{ @bytes.inspect }(#{ @bytes.length }))"
    end
  end

  class Image
    def to_raw
      image = self.class.from_blob(self.to_blob)
      image.format('r')

      RawImage.new(self[ :width ], self[ :height ], image.raw_data.bytes.to_a)
    end

    def raw_data
      File.open(@tempfile.path, 'rb') { |f| f.read }
    end
  end
end

filename = ARGV.first or raise 'Usage: capture_image <capatcha image>'

########################################################################################################
# Load the capatcha image, then crop it to the two character code.
########################################################################################################
$stderr.puts "Loading capatcha from '#{ filename }' ..."

capatcha_image = MiniMagick::Image.from_file(filename)
capatcha_image.combine_options do |steps|
  steps.colorSpace('Gray')
  steps.normalize
  steps.crop('18x12+2+10')
end
capatcha_raw = capatcha_image.to_raw

########################################################################################################
# Load each of the individual character images, correlating them with the capatcha.
########################################################################################################
$stderr.puts "Correlating all known characters with capatcha ..."

character_scored = (('a'..'z').to_a + ('0'..'9').to_a).inject({}) do |h,l|
  character_filename = "downloads/characters/individual/#{ l }.jpg"
  h[ l ] = MiniMagick::Image.from_file(character_filename).to_raw.correlate_with(capatcha_raw) if File.exists?(character_filename)
  h
end.to_a.sort do |a,b|
  compare = b.last <=> a.last
  compare = a.first <=> b.first if compare == 0
  compare
end

########################################################################################################
# Dump the scored characters.  Top two should be the code!
########################################################################################################
$stderr.puts "Character likelihoods:"
character_scored.each { |character,score| $stderr.puts "\t'#{ character }' = #{ score.inspect }" }

code = [ 
  character_scored[ 0 ], 
  character_scored[ 1 ]
].sort { |(_,c1),(_,c2)| c1.x <=> c2.x }.map { |c,_| c }.join
$stderr.puts "I reckon the code is: #{ code.upcase }"

$stderr.puts "Done"
