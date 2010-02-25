require 'spec_helper'

class LiveSetsUS::ContentDownloader
  expose(:private)
end

describe LiveSetsUS::ContentDownloader do
  before(:each) do
    @downloader = described_class.new('/tmp', 1)
  end

  describe '#handler_for' do
    it 'should pass the path to the handle method' do
      @downloader.should_receive(:handle).with('uri', 'capatcha id', 'path').and_return(:ok)
      @downloader.handler_for('path').call('uri', 'capatcha id').should == :ok
    end
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
  end

  describe '#correlation_for' do
    before(:each) do
      @yielded = mock('yielded')
      @exists = true
    end

    after(:each) do
      File.should_receive(:exists?).with('/tmp/character.jpg').and_return(@exists)
      @downloader.correlation_for('character', 'target') { |c| @yielded.call(c) }
    end

    it 'should not yield if the character template file does not exist' do
      @exists = false
    end

    it 'should yield if the character template file exists' do
      template_image = mock('template image')
      template_image.should_receive(:correlate_with).with('target').and_return(:correlation)
      MiniMagick::Image.should_receive(:from_file).with('/tmp/character.jpg').and_return(template_image)
      @yielded.should_receive(:call).with(:correlation)
    end
  end
end
