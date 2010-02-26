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

    @downloader = described_class.new('/tmp', 1)
  end

  describe '#download_large_file' do
    it 'should use axel' do
      @downloader.should_receive(:system).with("axel -n 3 -a -o 'destination' 'source'").and_return(:ok)
      @downloader.download_large_file('source', 'destination').should == :ok
    end
  end

  describe '#retrieve_download_link' do
    it 'should error if the link is not found' do
      @downloader.tries = 0
      lambda { @downloader.retrieve_download_link(:uri, :capatcha_id) }.should raise_error(StandardError)
    end

    describe 'different html' do
      after(:each) do
        FakeWeb.register_uri(:post, 'http://some.com/', :body => @body)

        @downloader.should_receive(:capatcha_image_for_processing).with('capatcha_id').and_return(:image)
        @downloader.should_receive(:guess_capatcha_code_in).with(:image).and_return('CODE')
        @downloader.retrieve_download_link('http://some.com/', 'capatcha_id').should == [ 'href.mp3', 'link' ]
      end

      it 'should handle the direct link' do
        @body = <<-END_OF_PAGE
          <html>
            <body>
              <div id="downloadpane">
                <a href="href.mp3">link</a>
              </div>
            </body>
          </html>
        END_OF_PAGE
      end
      
      it 'should have the javascript link' do
        @body = <<-END_OF_PAGE
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
      end
    end
  end

  describe '#handle' do

  end

  describe '#guess_capatcha_code_in' do
    def stub_correlation(name, left_score, right_score)
      correlation = mock(name)
      correlation.stub(:for).with(0).and_return(left_score)
      correlation.stub(:for).with(9).and_return(right_score)
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
    @downloader = described_class.new(File.join(ROOT_PATH, 'template-images'))
  end
  
  Dir.glob(File.join(ROOT_PATH, 'test-images', '*.jpg')) do |filename|
    expected_code = filename.match(/(..)\.jpg$/)[ 1 ]
    it "should recognise the code in #{ filename } as #{ expected_code }" do
      @downloader.guess_capatcha_code_in(MiniMagick::Image.from_file(filename)).should == expected_code
    end
  end
end
