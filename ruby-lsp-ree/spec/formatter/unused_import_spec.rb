# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([]) }

  it "removes unused import link" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link :some_import1
          link :some_import2
        end

        def call(arg1)
          some_import2
        end
      end
    RUBY

    result = subject.run_formatting(sample_file_uri, ruby_document(source))

    expect(result.lines[1].strip).to eq('fn :some_class do')
    expect(result.lines[2].strip).to eq('link :some_import2')
    expect(result.lines[3].strip).to eq('end')
  end

  # TODO it "removes unused import link from DSL-using object" do
  # TODO it "removes unused import link from spec" do
  # TODO it "removes do block if last unused import link removed" do
  # TODO it "removes unused import link if constant not used" do
  # TODO it "removes unused constant from import if not used" do
  # TODO it "removes unused constant from multi-constant import if not used" do
end
