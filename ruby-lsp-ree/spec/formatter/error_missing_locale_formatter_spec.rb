# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}) }

  before :each do
    @locales_cache = store_locales_cache
  end

  after :each do
    restore_locales_cache(@locales_cache)
  end

  it "adds error placeholders to locale files" do
    source =  <<~RUBY
      class SamplePackage::MyFile
        fn :some_class

        InvalidArg1Error = invalid_param_error(:some_error_code1)

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('my_file'), ruby_document(source))

    en_locale_content = File.read(sample_package_locales_dir + '/en.yml')
    ru_locale_content = File.read(sample_package_locales_dir + '/ru.yml')

    expect(en_locale_content.lines[10]).to match(/my_file:/)
    expect(ru_locale_content.lines[10]).to match(/my_file:/)

    expect(en_locale_content.lines[11]).to match(/some_error_code1: _MISSING_LOCALE_/)
    expect(ru_locale_content.lines[11]).to match(/some_error_code1: _MISSING_LOCALE_/)
  end

  it "doesn't add error placeholder if code follows package-specific convention" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:some_error_code)

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('some_class'), ruby_document(source))

    en_locale_content = File.read(sample_package_locales_dir + '/en.yml')
    ru_locale_content = File.read(sample_package_locales_dir + '/ru.yml')

    expect(en_locale_content.lines.select{ _1.match?(/some_error_code: _MISSING_LOCALE_/) }.size).to eq(0)
    expect(ru_locale_content.lines.select{ _1.match?(/some_error_code: _MISSING_LOCALE_/) }.size).to eq(0)
  end

  it "doesn't add error placeholder if code follows class-specific convention" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:class_specific_error_code)

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('some_class'), ruby_document(source))

    en_locale_content = File.read(sample_package_locales_dir + '/en.yml')
    ru_locale_content = File.read(sample_package_locales_dir + '/ru.yml')

    expect(en_locale_content.lines.select{ _1.match?(/class_specific_error_code: _MISSING_LOCALE_/) }.size).to eq(0)
    expect(ru_locale_content.lines.select{ _1.match?(/class_specific_error_code: _MISSING_LOCALE_/) }.size).to eq(0)
  end

  it "adds several levels of keys for error placeholders" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class

        InvalidArg1Error = invalid_param_error(:some_error_code1, 'new_error_code.my_new_code')

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    subject.run_formatting(sample_file_uri, ruby_document(source))

    en_locale_content = File.read(sample_package_locales_dir + '/en.yml')
    expect(en_locale_content.lines[1].strip).to eq('new_error_code:')
    expect(en_locale_content.lines[2].strip).to eq('my_new_code: _MISSING_LOCALE_')
  end
end
