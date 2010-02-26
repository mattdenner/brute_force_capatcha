require 'mini_magick'

# Simple image manipulation
module MiniMagick #:nodoc:
  # An instance of this class holds the image data in the raw format.
  class RawImage #:nodoc:
    attr_reader :width, :height

    def initialize(width, height, bytes)
      @width, @height, @bytes = width, height, bytes
    end

    def correlate_with(image, range = (0...image.width - self.width))
      range.inject({}) do |correlations,image_column|
        correlations[ image_column ] =
          @bytes.each_with_index.inject(0) do |value,(byte,index)|
            value + (image.at((index % self.width) + image_column, index.div(self.width)) - byte).abs
          end
        correlations
      end
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

