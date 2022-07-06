# frozen_string_literal: true

require 'uri'

class ReeValidator::ValidateUrl
  include Ree::FnDSL

  fn :validate_url do
    link :t, from: :ree_i18n

    def_error(:validation) { InvalidUrlErr }
    def_error(:validation) { InvalidSchemeErr }
    def_error(:validation) { InvalidPortErr }
    def_error(:validation) { InvalidDomainErr }
  end

  contract(
    String,
    Symbol,
    Ksplat[
      schemes?: ArrayOf[String],
      ports?: ArrayOf[Integer],
      domains?: ArrayOf[String],
    ] => Bool
  ).throws(InvalidUrlErr)
  def call(url, error_code, **opts)
    begin
      uri = URI.parse(url)

      if opts[:schemes] && (opts[:schemes] & [uri.scheme]).size == 0
        raise InvalidSchemeErr.new(
          t('validator.url.invalid_scheme', {schemes: opts[:schemes]}, default_by_locale: :en),
          error_code
        )
      end

      if opts[:ports] && (opts[:ports] & [uri.port]).size == 0
        raise InvalidPortErr.new(
          t('validator.url.invalid_port', {ports: opts[:ports]}, default_by_locale: :en),
          error_code
        )
      end

      if opts[:domains] && (opts[:domains] & [uri.hostname]).size == 0
        raise InvalidDomainErr.new(
          t(
            'validator.url.invalid_domain', {domains: opts[:domains]}, default_by_locale: :en),
          error_code
        )
      end
    rescue URI::InvalidURIError
      raise InvalidUrlErr.new(
        t('validator.url.invalid_url', default_by_locale: :en),
        error_code
      )
    end

    true
  end
end