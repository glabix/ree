# frozen_string_literal: true

RSpec.describe :t do
  link :add_load_path, from: :ree_i18n
  link :set_locale, from: :ree_i18n
  link :t, from: :ree_i18n

  before do
    add_load_path(Dir[File.join(__dir__, 'locales/*.yml')])
  end

  it {
    set_locale(:ru)

    expect(t('gender.male')).to eq("Мужской")
    expect(t('gender.missing')).to eq("Translation missing: ru.gender.missing")

    expect {
      t('gender.missing', raise: true)
    }.to raise_error(I18n::MissingTranslationData)

    expect {
      t('gender.missing', raise: true, locale: :fr)
    }.to raise_error(I18n::InvalidLocale)

    expect {
      t('gender.missing', throw: true)
    }.to raise_error(UncaughtThrowError)

    expect {
      t(
        'gender.missing',
        exception_handler: Proc.new { |*args| raise ArgumentError, "proc_exception_handler" }
      )
    }.to raise_error(ArgumentError) do |e|
      expect(e.message).to eq("proc_exception_handler")
    end

    expect {
      module I18n
        def self.custom_exception_handler(exception, locale, key, options)
          raise ArgumentError, "custom_exception_handler"
        end
      end

      t(
        'gender.missing',
        exception_handler: :custom_exception_handler
      )
    }.to raise_error(ArgumentError) do |e|
      expect(e.message).to eq("custom_exception_handler")
    end
  }

  context "default_by_locale" do
    it {
      expect(t('gender.other', default_by_locale: :en, locale: :ru)).to eq("Other")
    }

    it {
      expect(
        t('gender.other', default_by_locale: :en, locale: :ru)
      ).to eq("Other")
    }
  end

  context "locale" do
    it {
      expect(t('gender.male', locale: :ru)).to eq("Мужской")
      expect(t('gender.male', locale: :en)).to eq("Male")
    }
  end

  context "count" do
    it {
      expect(t('count', count: 2, locale: :en)).to eq("other")
      expect(t('count', count: 1, locale: :ru)).to eq("один")
      expect(t('count', count: 0, locale: :en)).to eq("zero")

      expect {
        t('count', count: 2, locale: :ru)
      }.to raise_error(I18n::InvalidPluralizationData)
    }
  end

  context "scope" do
    it {
      expect(t('male', scope: 'gender', locale: :ru)).to eq("Мужской")
      expect(t('male', scope: 'gender', locale: :en)).to eq("Male")
    }
  end

  context "default" do
    it {
      expect(t('gender.missing', default: 'Default', locale: :ru)).to eq("Default")
      expect(t('gender.missing', default: :'gender.male', locale: :ru)).to eq("Мужской")
    }
  end

  context "deep_interpolation" do
    it {
      set_locale(:en)

      expect(t('welcome', {app_name: 'book store'})).to eq(
        {title:"Welcome!", content: "Welcome to the %{app_name}"}
      )

      expect(t('welcome', {app_name: 'book store'}, deep_interpolation: true)).to eq(
        {title:"Welcome!", content: "Welcome to the book store"}
      )
    }
  end
end
