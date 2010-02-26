require 'mini_magick'

# Simple image manipulation
module MiniMagick #:nodoc:
  # An instance of this class holds the image data in the raw format.
  class RawImage #:nodoc:
    # Stores the correlation value for a given position.
    class Correlation #:nodoc:
      attr_reader :x, :y, :likelihood

      def initialize(column, row, likelihood, likelihoods = nil)
        @x, @y, @likelihood, @likelihoods = column, row, likelihood, likelihoods
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
      correlations = [ 0, 9 ].inject([]) do |results,image_column|
        results << [
          (0...self.height).inject(0) do |v1,template_row|
            (0...self.width).inject(v1) do |v2,template_column|
              v2 + (image.at(image_column + template_column, template_row) - self.at(template_column, template_row)).abs
            end
          end,
          image_column
        ]
      end

      correlation, correlation_x = correlations.sort { |left,right| left.first <=> right.first }.first
      Correlation.new(correlation_x, 0, correlation, correlations)
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

      RawImage.new(self[ :width ], self[ :height ], image.raw_data.bytes.to_a)
    end

    def raw_data
      File.open(@tempfile.path, 'rb') { |f| f.read }
    end

    def correlate_with(image)
      self.to_raw.correlate_with(image.to_raw)
    end
  end
end

