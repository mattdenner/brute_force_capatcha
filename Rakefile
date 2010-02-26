require 'rubygems'
require 'rake'

require 'spec/rake/spectask'

Spec::Rake::SpecTask.new do |task|
  task.spec_files = FileList[ 'spec/**/*_spec.rb' ]
end

require 'jeweler'

Jeweler::Tasks.new do |gemspec|
  gemspec.name        = 'mattdenner-brute_force_capatcha'
  gemspec.summary     = 'Code for cracking the livesets.us capatchas'
  gemspec.description = 'Applies normalised cross correlation to break the livesets.us capatchas'
  gemspec.email       = 'matt.denner@gmail.com'
  gemspec.homepage    = 'http://github.com/mattdenner/brute_force_capatcha'
  gemspec.authors     = [ 'Matthew Denner' ]

  gemspec.add_bindir('download-mp3')
  gemspec.add_bindir('extract-template-images')

  %w{ rspec jeweler fakeweb }.each { |d| gemspec.add_development_dependency(d) }
  %w{ activesupport nokogiri mattdenner-mini_magick }.each { |d| gemspec.add_runtime_dependency(d) }
end
Jeweler::GemcutterTasks.new
