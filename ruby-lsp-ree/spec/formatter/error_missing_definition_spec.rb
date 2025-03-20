# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new }

  it "adds error definition raised error" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    document = RubyLsp::RubyDocument.new(source: source, version: 1, uri: URI.parse(''), global_state: RubyLsp::GlobalState.new)
    result = subject.run_formatting(sample_file_uri, document)

    expect(result.lines[3].strip).to eq('InvalidArg1Error = invalid_param_error(:invalid_arg1_error)')
  end

  # TODO it "adds error definition after last esisting definition" do
  # TODO it "adds error definition after fn block" do
  # TODO it "adds error on 'raise ErrorClass'" do
  # TODO it "correctly adds multiple error definitions" do
  # TODO it "doesn't add definition on 'raise string'" do
  # TODO it "doesn't add definition for imported error" do
end
