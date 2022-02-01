# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/messaging/version'

Gem::Specification.new do |spec|
  spec.name                  = "manageiq-messaging"
  spec.version               = ManageIQ::Messaging::VERSION
  spec.required_ruby_version = '>= 2.4'
  spec.authors               = ["ManageIQ Authors"]

  spec.summary       = 'Client library for ManageIQ components to exchange messages through its internal message bus.'
  spec.description   = 'Client library for ManageIQ components to exchange messages through its internal message bus.'
  spec.homepage      = 'http://github.com/ManageIQ/manageiq-messaging'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', '>= 5.2.4.3', "< 7.0"
  spec.add_dependency 'rdkafka', '~> 0.8'
  spec.add_dependency 'stomp', '~> 1.4.4'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov"
end
