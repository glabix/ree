# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new }

  before :each do
    @cached_en_locale = File.read(sample_package_locales_dir + '/en.yml')
    @cached_ru_locale = File.read(sample_package_locales_dir + '/ru.yml')
  end

  it "adds error placeholders to locale files" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:invalid_arg1_error)
        InvalidArg2Error = invalid_param_error(:invalid_arg2_error, "some_unexisting_locale_path.some_unexsting_locale_path")

        contract(Integer => nil).throws(InvalidArg2Error)
        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    subject.run_formatting(sample_file_uri, ruby_document(source))


    en_locale_content = File.read(sample_package_locales_dir + '/en.yml')
    ru_locale_content = File.read(sample_package_locales_dir + '/ru.yml')
    expect(en_locale_content.lines[7]).to match(/MISSING_LOCALE/)
    expect(ru_locale_content.lines[7]).to match(/MISSING_LOCALE/)
  end

  # TODO it "adds several levels of keys for error placeholders" do
  
  after :each do
    File.write(sample_package_locales_dir + '/en.yml', @cached_en_locale)
    File.write(sample_package_locales_dir + '/ru.yml', @cached_ru_locale)
  end
end
