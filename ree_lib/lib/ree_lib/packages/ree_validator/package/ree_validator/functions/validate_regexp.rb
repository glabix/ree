# frozen_string_literal: true

class ReeValidator::ValidateRegexp
  include Ree::FnDSL

  fn :validate_regexp do
    link :t, from: :ree_i18n

    def_error(:validation) { RegexpErr }
  end

  contract(String, Regexp, Symbol => Bool)
  def call(value, regexp, error_code)
    if !regexp.match(value)
      raise RegexpErr.new(
        t('validator.regexp.error', {regexp: regexp.inspect}, default_by_locale: :en),
        error_code
      )
    end

    true
  end
end