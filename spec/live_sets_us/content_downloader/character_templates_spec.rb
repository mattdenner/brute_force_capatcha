require 'spec_helper'

describe LiveSetsUS::ContentDownloader::CharacterTemplates do
  describe '#initialize' do
    it 'should delegate to the block passed' do
      receiver = mock('receiver')
      ('a'..'z').each { |c| receiver.should_receive(:received).with(an_instance_of(Hash), c) }
      ('0'..'9').each { |c| receiver.should_receive(:received).with(an_instance_of(Hash), c) }

      described_class.new do |m,c|
        receiver.received(m, c)
        m[ c ] = true
      end
    end

    it 'should raise if there are no template images' do
      lambda { described_class.new { |m,c| } }.should raise_error(StandardError)
    end
  end

  describe '#correlate_with' do
    it 'should score against each template image' do
      template_image_a = mock('template image a')
      template_image_a.should_receive(:correlate_with).with(:image).and_return(10)

      template_image_b = mock('template image b')
      template_image_b.should_receive(:correlate_with).with(:image).and_return(10)

      described_class.new do |m,c|
        m[ 'a' ] = template_image_a
        m[ 'b' ] = template_image_b
      end.correlate_with(:image).should == [ 
        [ 'a', 10 ], 
        [ 'b', 10 ] 
      ]
    end
  end
end
