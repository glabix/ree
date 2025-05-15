# frozen_string_literal: true

require_relative "lib/ree_spec/version"

Gem::Specification.new do |spec|
  spec.name = "ree_spec"
  spec.version = ReeSpec::VERSION
  spec.authors = ["Ruslan Gatiyatov"]
  spec.email = ["ruslan.gatiyatov@gmail.com"]

  spec.summary = "Ree extensions for Rspec framework"
  spec.description = "Ree Spec provides executable to run Rspec suite for Ree packages"
  spec.homepage = "https://github.com/glabix/ree/tree/main/ree_spec"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/glabix/ree/tree/main/ree_spec"
  spec.metadata["changelog_uri"] = "https://github.com/glabix/ree/blob/main/ree_spec/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "ree", "~> 1.1.0"
  spec.add_dependency "ree_lib", "~> 1.2.0"
  spec.add_dependency "commander", "~> 5.0.0"
end
