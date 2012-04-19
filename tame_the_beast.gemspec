# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tame_the_beast/version"

Gem::Specification.new do |s|
  s.name        = "tame_the_beast"
  s.version     = TameTheBeast::VERSION
  s.authors     = ["Thomas Stratmann"]
  s.email       = ["thomas.stratmann@9elements.com"]
  s.homepage    = ""
  s.summary     = %q{Systematic dependency injection: keep your singletons manageable}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "ruby-debug"
  s.add_development_dependency "rspec", "2.8.0"
  s.add_development_dependency "growl"
  s.add_development_dependency "guard-rspec"
end
