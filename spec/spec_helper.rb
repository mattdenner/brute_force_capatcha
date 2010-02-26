require 'rubygems'

require 'fakeweb'
FakeWeb.allow_net_connect = false

require 'live_sets_us'

class Class
  def expose(scope)
    self.send("#{ scope }_instance_methods").each { |m| public(m) }
  end
end

LiveSetsUS::Processor.logger.level = Logger::ERROR
