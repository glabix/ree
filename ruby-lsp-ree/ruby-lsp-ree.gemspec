# frozen_string_literal: true

require_relative "lib/ruby_lsp_ree/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-lsp-ree"
  spec.version = RubyLsp::Ree::VERSION
  spec.authors = ["Ruslan Gatiyatov"]
  spec.email = ["ruslan.gatiyatov@gmail.com"]

  spec.summary = "Ruby LSP addon for Ree framework."
  spec.description = "A Ruby LSP addon that adds extra editor functionality for Ree applications"
  spec.homepage = "https://github.com/glabix/ree/tree/main/ruby-lsp-ree"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/glabix/ree/tree/main/ruby-lsp-ree"
  spec.metadata["changelog_uri"] = "https://github.com/glabix/ree/blob/main/ruby-lsp-ree/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
