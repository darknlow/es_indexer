# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "electric_eye"
  spec.version       = "0.1"
  spec.authors       = ["Nikos"]
  spec.email         = ["nikos@heathen-natives.gr"]

  spec.summary       = "Write a short summary, because RubyGems requires one."
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new("~> 3.3")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_dependency "mongo", "~> 2.21"
  spec.add_dependency "zeitwerk", "~> 2.3"
  spec.add_dependency "starman"
  spec.add_dependency "elasticsearch", "~> 9.0"
end
