# frozen_string_literal: true

require_relative "lib/ree_lib/version"

Gem::Specification.new do |spec|
  spec.name = "ree_lib"
  spec.version = ReeLib::VERSION
  spec.authors = ["Ruslan Gatiyatov"]
  spec.email = ["ruslan.gatiyatov@gmail.com"]

  spec.summary = "Ruby Standard Library Extensions"
  spec.description = "Ree Lib provides set of packages to extend Ruby Standard Library"
  spec.homepage = "https://github.com/glabix/ree/ree_lib"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/glabix/ree/ree_lib"
  spec.metadata["changelog_uri"] = "https://github.com/glabix/ree/ree_lib/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ree"
  spec.add_dependency "tzinfo"
  spec.add_dependency "loofah"
  spec.add_dependency "oj"
  spec.add_dependency "i18n"
  spec.add_dependency "sequel"
  spec.add_dependency "binding_of_caller"
  spec.add_dependency "rainbow"

  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'timecop'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
