require "#{File.dirname(__FILE__)}/lib/hl/version"

Gem::Specification.new do |s|
  s.name = "hl"
  s.version = HL::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Korei Klein"]
  s.email = ["korei@hatchlearn.com"]
  s.homepage = ""
  s.summary = "Command line tool for interacting with a HatchLearn learning repository."
  s.description = "Command line tool for interacting with a HatchLearn learning repository."
  s.files = Dir.glob("{bin,lib,test,examples,doc,data}/**/*") + %w(README.md)
  s.require_path = 'lib'
  s.executables = ["hl"]
  s.required_ruby_version = ">= 1.9.2"
  s.required_rubygems_version = ">= 1.3.6"
end
