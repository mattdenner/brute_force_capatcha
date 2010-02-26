require 'spec_helper'
require 'ostruct'

class LiveSetsUS::ContentDownloader
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

  describe '#handle' do
    it 'should download the expected file' do
      FakeWeb.register_uri(
        :post, 'http://some.com/',
        :body => <<-END_OF_PAGE
          <html>
            <body>
              <div id="downloadpane">
                <a href="href">link</a>
              </div>
            </body>
          </html>
        END_OF_PAGE
      )

      @downloader.should_receive(:capatcha_image_for_processing).with('capatcha_id').and_return(:image)
      @downloader.should_receive(:guess_capatcha_code_in).with(:image).and_return('CODE')
      @downloader.should_receive(:download_large_file).with('href', '/tmp/link').and_return(:ok)
      @downloader.handle('http://some.com/', 'capatcha_id', '/tmp').should == :ok
    end
  end

  describe '#guess_capatcha_code_in' do
    it 'should upcase the characters' do
      @templates.should_receive(:correlate_with).with(:image).and_return([
        [ 'l', OpenStruct.new(:x => 0) ],
        [ 'r', OpenStruct.new(:x => 10) ]
      ])
      
      @downloader.guess_capatcha_code_in(:image).should == 'LR'
    end

    it 'should order based on the x position' do
      @templates.should_receive(:correlate_with).with(:image).and_return([
        [ 'l', OpenStruct.new(:x => 10) ],
        [ 'r', OpenStruct.new(:x => 0) ]
      ])
      
      @downloader.guess_capatcha_code_in(:image).should == 'RL'
    end

    it 'should select the first two characters' do
      @templates.should_receive(:correlate_with).with(:image).and_return([
        [ 'l', OpenStruct.new(:x => 0) ],
        [ 'r', OpenStruct.new(:x => 10) ],
        [ 'a', OpenStruct.new(:x => 20) ],
        [ 'b', OpenStruct.new(:x => 30) ]
      ])
      
      @downloader.guess_capatcha_code_in(:image).should == 'LR'
    end
  end
end
