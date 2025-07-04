require_relative "lib/edifact/version"

Gem::Specification.new do |spec|
  spec.name          = "edifact"
  spec.version       = Edifact::VERSION
  spec.authors       = ["Michael Goth"]
  spec.email         = ["iqe@gmx.net"]

  spec.summary       = "A validating parser and builder for EDIFACT messages"
  spec.description   = "A library to work with EDIFACT messages in pure Ruby. It supports parsing, validating, and building messages according to the EDIFACT standard."
  spec.homepage      = "https://github.com/iqe/edifact"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
