# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "translator"
  s.version     = "0.2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jacqui Maher", "Hubert Lepicki"]
  s.email       = ["jacqui.maher@nytimes.com", "hubert.lepicki@amberbit.com"]
  s.homepage    = "http://github.com/jacqui/translator"
  s.summary     = "Rails engine to manage translations, modified for our projects"
  s.description = "translator is an engine that easily integrates with your rails app"

  s.required_rubygems_version = ">= 1.3.6"

  s.files        = Dir.glob("{app,lib,config}/**/*") + %w(LICENSE README.rdoc)
  s.require_path = 'lib'
end

