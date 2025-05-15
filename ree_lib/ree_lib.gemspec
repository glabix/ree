# frozen_string_literal: true

require_relative "lib/ree_lib/version"

Gem::Specification.new do |spec|
  spec.name = "ree_lib"
  spec.version = ReeLib::VERSION
  spec.authors = ["Ruslan Gatiyatov"]
  spec.email = ["ruslan.gatiyatov@gmail.com"]

  spec.summary = "Ruby Standard Library Extensions"
  spec.description = "Ree Lib provides set of packages to extend Ruby Standard Library"
  spec.homepage = "https://github.com/glabix/ree/tree/main/ree_lib"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/glabix/ree/tree/main/ree_lib"
  spec.metadata["changelog_uri"] = "https://github.com/glabix/ree/blob/main/ree_lib/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ree", "~> 1.1.2"
  spec.add_dependency "tzinfo", "~> 2.0.6"
  spec.add_dependency "loofah", "~> 2.24.0"
  spec.add_dependency "oj", "~> 3.16.9"
  spec.add_dependency "i18n", "~> 1.14.7"
  spec.add_dependency "sequel", "~> 5.88.0"
  spec.add_dependency "binding_of_caller", "~> 1.0.1"
  spec.add_dependency "rainbow", "~> 3.1.1"
  spec.add_dependency "bigdecimal", "~> 3.1.9"

  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'roda', "~> 3.88.0"
  spec.add_development_dependency 'sqlite3', "~> 2.5.0"
  spec.add_development_dependency 'pg', "~> 1.5.9"
  spec.add_development_dependency 'warden', "~> 1.2.9"
  spec.add_development_dependency 'timecop', "~> 0.9.10"
  spec.add_development_dependency "rollbar", "~> 3.6.0"
  spec.add_development_dependency "faker", "~> 3.5.1"
end
