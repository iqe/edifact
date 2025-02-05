Gem::Specification.new do |spec|
  spec.name          = "edifact"
  spec.version       = Edifact::VERSION
  spec.authors       = ["Michael Goth"]
  spec.email         = ["iqe@gmx.net"]

  spec.summary       = %q{A library to parse EDIFACT}
  spec.description   = %q{A validating parser for EDIFACT messages}
  spec.homepage      = "https://github.com/iqe/edifact"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end