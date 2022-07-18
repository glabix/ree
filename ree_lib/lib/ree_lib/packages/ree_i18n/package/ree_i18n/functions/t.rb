# frozen_string_literal: true

require 'set'

class ReeI18n::T
  include Ree::FnDSL

  fn :t do
    link :except, from: :ree_hash
  end

  DEFAULT_BY_LOCALE = Object.new

  RESERVED_KEYS = Set.new([
    :throw, :raise, :locale, :scope, :default, :deep_interpolation,
    :count, :exception_handler, :default_by_locale
  ])

  doc(<<~DOC)
    Translates, pluralizes and interpolates a given key using a given locale,
    scope, and default, as well as interpolation values.

    Full args example:
      t(
        :salutation,
        {gender: 'w', name: 'Smith'},
        {
          throw: false,
          raise: false,
          locale: :en,
          scope: :people,
          default: :person,
          deep_interpolation: true,
          count: 1,
          exception_handler?: Proc.new { |*args| ...},
          default_by_locale: :en
        }
      )
  DOC
  contract(
    Nilor[Or[String, Symbol]],
    HashOf[Or[String, Symbol], Any],
    Ksplat[
      throw?: Bool,
      raise?: Bool,
      locale?: Symbol,
      scope?: Or[String, Symbol],
      default?: Or[String, Symbol],
      deep_interpolation?: Bool,
      count?: Integer,
      exception_handler?: Or[Symbol, Proc],
      default_by_locale?: Or[Symbol],
    ] => Or[String, Hash]
  ).throws(
    ArgumentError,
    I18n::Disabled, I18n::MissingTranslation, I18n::InvalidLocale,
    I18n::ArgumentError, UncaughtThrowError, I18n::InvalidPluralizationData
  )
  def call(key = nil, context = {}, **options)
    context.each do |k, _|
      if RESERVED_KEYS.include?(k)
        raise ArgumentError, "translation context contains reserved key :#{k}"
      end
    end

    opts = context.merge(options)
    default_by_locale = opts.delete(:default_by_locale)

    if default_by_locale && !opts[:default]
      opts[:default] = DEFAULT_BY_LOCALE
    end

    opts[:throw] ||= false
    opts[:raise] ||= false
    opts[:locale] ||= nil

    result = I18n.t(key, **opts)

    if result == DEFAULT_BY_LOCALE
      result = call(
        key, context,
        **except(
          options.merge(locale: default_by_locale), [:default_by_locale]
        )
      )
    end

    result
  end
end