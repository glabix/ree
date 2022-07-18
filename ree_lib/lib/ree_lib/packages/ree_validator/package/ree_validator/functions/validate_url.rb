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
    Nilor[StandardError],
    Ksplat[
      schemes?: ArrayOf[String],
      ports?: ArrayOf[Integer],
      domains?: ArrayOf[String],
    ] => Bool
  ).throws(UrlErr)
  def call(url, error = nil, **opts)
    begin
      uri = URI.parse(url)

      if opts[:schemes] && (opts[:schemes] & [uri.scheme]).size == 0
        error ||= UrlErr.new(
          t(
            'validator.url.invalid_scheme',
            {schemes: opts[:schemes]},
            default_by_locale: :en
          )
        )

        raise error
      end

      if opts[:ports] && (opts[:ports] & [uri.port]).size == 0
        error ||= UrlErr.new(
          t(
            'validator.url.invalid_port',
            {ports: opts[:ports]},
            default_by_locale: :en
          )
        )

        raise error
      end

      if opts[:domains] && (opts[:domains] & [uri.hostname]).size == 0
        error ||= UrlErr.new(
          t(
            'validator.url.invalid_domain',
            {domains: opts[:domains]},
            default_by_locale: :en
          )
        )

        raise error
      end
    rescue URI::InvalidURIError
      error ||= UrlErr.new(
        t(
          'validator.url.invalid_url',
          default_by_locale: :en
        )
      )

      raise error
    end

    true
  end
end