# frozen_string_literal: true

require 'uri'

class ReeValidator::ValidateUrl
  include Ree::FnDSL

  fn :validate_url do
    link :t, from: :ree_i18n
  end

  UrlErr = Class.new(StandardError)

  contract(
    String,
    Nilor[SubclassOf[StandardError]],
    Ksplat[
      schemes?: ArrayOf[String],
      ports?: ArrayOf[Integer],
      domains?: ArrayOf[String],
    ] => Bool
  ).throws(UrlErr)
  def call(url, error = nil, **opts)
    begin
      uri = URI.parse(url)

      klass = error || UrlErr

      if opts[:schemes] && (opts[:schemes] & [uri.scheme]).size == 0
        raise klass.new(
          t(
            'validator.url.invalid_scheme',
            {schemes: opts[:schemes]},
            default_by_locale: :en
          )
        )
      end

      if opts[:ports] && (opts[:ports] & [uri.port]).size == 0
        raise klass.new(
          t(
            'validator.url.invalid_port',
            {ports: opts[:ports]},
            default_by_locale: :en
          )
        )
      end

      if opts[:domains] && (opts[:domains] & [uri.hostname]).size == 0
        raise klass.new(
          t(
            'validator.url.invalid_domain',
            {domains: opts[:domains]},
            default_by_locale: :en
          )
        )
      end
    rescue URI::InvalidURIError
      raise klass.new(
        t(
          'validator.url.invalid_url',
          default_by_locale: :en
        )
      )
    end

    true
  end
end