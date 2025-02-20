# frozen_string_literal: true

require "sorbet-runtime"
require "ruby_lsp/test_helper"
require "ruby_lsp/internal"
require "ruby_lsp_ree"
require "ruby_lsp/ruby_lsp_ree/addon"

RSpec.configure do |config|
  include RubyLsp::TestHelper

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
