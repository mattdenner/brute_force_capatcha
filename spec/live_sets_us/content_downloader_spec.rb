require 'spec_helper'
require 'ostruct'

class LiveSetsUS::ContentDownloader
  attr_accessor :tries
  expose(:private)
end

describe LiveSetsUS::ContentDownloader do
  before(:each) do
    @templates = mock('template images')
    described_class.should_receive(:initialize_template_images_from).with('/tmp').and_return(@templates)

    @callback = mock('callback')
    @downloader = described_class.new('/tmp', 1) { |*args| @callback.called_with(*args) }
  end

  describe '#download_large_file' do
    it 'should use axel' do
      @callback.should_receive(:called_with).with('source', 'destination').and_return(:ok)
      @downloader.download_large_file('source', 'destination').should == :ok
    end
  end

  describe '#link_from_anchor' do
    it 'should return the details from the anchor' do
      @downloader.link_from_anchor(Nokogiri::HTML(<<-END_OF_PAGE
          <html>
            <body>
              <div id="downloadpane">
                <a href="href.mp3">link</a>
              </div>
            </body>
          </html>
        END_OF_PAGE
      )).should == [ 'href.mp3', 'link' ]
    end
  end

  describe '#link_from_script' do
    it 'should return the details from the anchor' do
      @downloader.link_from_script(Nokogiri::HTML(<<-END_OF_PAGE
          <html>
            <body>
              <div id="downloadpane">
                <script language="Javascript"><![CDATA[
                  <a href="href.mp3">link</a>
                ]]></script>
              </div>
            </body>
          </html>
        END_OF_PAGE
      )).should == [ 'href.mp3', 'link' ]
    end
  end

  describe '#attempt_retrieve_download_link' do
    before(:each) do
      @downloader.tries = 5
    end

    it 'should repeat for the number of tries' do
      lambda do
        @downloader.should_receive(:retrieve_download_link).exactly(5).with('uri', 'capatcha_id').and_return(nil)
        @downloader.attempt_retrieve_download_link('uri', 'capatcha_id')
      end.should raise_error(StandardError)
    end

    it 'should return early if there is a match' do
      @downloader.should_receive(:retrieve_download_link).exactly(3).with('uri', 'capatcha_id').and_return(nil, nil, :ok)
      @downloader.attempt_retrieve_download_link('uri', 'capatcha_id').should == :ok
    end
  end

  describe '#retrieve_download_link' do

  end

  describe '#handle' do
    it 'should download the appropriate file' do
      @downloader.should_receive(:attempt_retrieve_download_link).with('uri', 'capatcha id').and_return([ 'href', 'file' ])
      @downloader.should_receive(:download_large_file).with('href', 'path/file')

      @downloader.handle('uri', 'capatcha id', 'path')
    end
  end

  describe '#guess_capatcha_code_in' do
    def stub_correlation(name, left_score, right_score)
      correlation = mock(name)
      correlation.stub(:[]).with(0).and_return(left_score)
      correlation.stub(:[]).with(9).and_return(right_score)
      correlation
    end

    it 'should upcase the characters' do
      @templates.should_receive(:correlate_with).with(:image, [ 0, 9 ]).and_return([
        [ 'l', stub_correlation('left', 0, 10) ],
        [ 'r', stub_correlation('right', 10, 0) ]
      ])
      
      @downloader.guess_capatcha_code_in(:image).should == 'LR'
    end

    it 'should order based on the x position' do
      @templates.should_receive(:correlate_with).with(:image, [ 0, 9 ]).and_return([
        [ 'l', stub_correlation('left', 10, 0) ],
        [ 'r', stub_correlation('right', 0, 10) ]
      ])
      
      @downloader.guess_capatcha_code_in(:image).should == 'RL'
    end

    it 'should be able to guess the same character on both sides' do
      @templates.should_receive(:correlate_with).with(:image, [ 0, 9 ]).and_return([
        [ 'l', stub_correlation('left', 10, 10) ],
        [ 'r', stub_correlation('right', 0, 0) ]
      ])
      
      @downloader.guess_capatcha_code_in(:image).should == 'RR'
    end

    it 'should select the optimum characters for each side' do
      @templates.should_receive(:correlate_with).with(:image, [ 0, 9 ]).and_return([
        [ 'l', stub_correlation('left', 0, 10) ],
        [ 'a', stub_correlation('invalid left', 1, 11) ],
        [ 'r', stub_correlation('right', 10, 0) ],
        [ 'b', stub_correlation('invlaid right', 11, 1) ]
      ])
      
      @downloader.guess_capatcha_code_in(:image).should == 'LR'
    end
  end
end

describe LiveSetsUS::ContentDownloader do
  ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', 'images'))
  
  before(:all) do
    @callback = mock('callback')
    @downloader = described_class.new(File.join(ROOT_PATH, 'template-images')) { |*args| @callback.called_with(*args) }
  end
  
  Dir.glob(File.join(ROOT_PATH, 'test-images', '*.jpg')) do |filename|
    expected_code = filename.match(/(..)\.jpg$/)[ 1 ]
    it "should recognise the code in #{ filename } as #{ expected_code }" do
      @downloader.guess_capatcha_code_in(MiniMagick::Image.from_file(filename)).should == expected_code
    end
  end
end
