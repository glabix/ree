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

        InvalidArg1Error = invalid_param_error(:some_error_code1)

        def call(arg1)
          raise InvalidArg1Error.new
        end
      end
    RUBY

    subject.run_formatting(sample_file_uri, ruby_document(source))


    en_locale_content = File.read(sample_package_locales_dir + '/en.yml')
    ru_locale_content = File.read(sample_package_locales_dir + '/ru.yml')
    expect(en_locale_content.lines[11]).to match(/_MISSING_LOCALE_/)
    expect(ru_locale_content.lines[11]).to match(/_MISSING_LOCALE_/)
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
  
  after :each do
    File.write(sample_package_locales_dir + '/en.yml', @cached_en_locale)
    File.write(sample_package_locales_dir + '/ru.yml', @cached_ru_locale)
  end
end
