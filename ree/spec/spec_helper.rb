# frozen_string_literal: true

require "ree"
require "fileutils"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def sample_project_dir
  @sample_project_dir ||= File.expand_path(
    File.join(__dir__, 'sample_project')
  )
end

def ensure_exists(file)
  expect(File.exist?(file)).to be true
end

def ensure_not_exists(file)
  expect(!File.exist?(file)).to be true
end

def with_captured_stdout
  original_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = original_stdout
end

Ree.init(sample_project_dir)
