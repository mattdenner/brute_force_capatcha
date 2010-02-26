require 'mini_magick'

# Simple image manipulation
module MiniMagick #:nodoc:
  # An instance of this class holds the image data in the raw format.
  class RawImage #:nodoc:
    class Correlations #:nodoc:
      def initialize(correlations)
        @correlations = correlations
      end

      def for(position)
        @correlations.find { |value,index| index == position }.first
      end
    end

    attr_reader :width, :height

    def initialize(width, height, bytes)
      @width, @height, @bytes = width, height, bytes
    end

    def correlate_with(image, range = (0...image.width - self.width))
      Correlations.new(range.map do |image_column|
        [
          (0...self.height).inject(0) do |v1,template_row|
            (0...self.width).inject(v1) do |v2,template_column|
              v2 + (image.at(image_column + template_column, template_row) - self.at(template_column, template_row)).abs
            end
          end,
          image_column
        ]
      end)
    end
    
    def at(column, row)
      @bytes[ (row * self.width) + column ] or raise "(#{ column },#{ row }) = #{ self.inspect }"
    end

    def inspect #:nodoc:
      "RawImage(#{ @width }x#{ @height }, #{ @bytes.inspect }(#{ @bytes.length }))"
    end
  end

  # Some extensions to this class to make correlation easier.
  class Image #:nodoc:
    def to_raw
      image = self.class.from_blob(self.to_blob)
      image.format('r')

      RawImage.new(self[ :width ], self[ :height ], image.to_blob.bytes.to_a)
    end

    def correlate_with(image, *args)
      self.to_raw.correlate_with(image.to_raw, *args)
    end
  end
end

