# frozen_string_literal: true

class ReeValidator::ValidateRegexp
  include Ree::FnDSL

  fn :validate_regexp do
    link :t, from: :ree_i18n
  end

  RegexpErr = Class.new(StandardError)

  contract(
    String,
    Regexp,
    Nilor[StandardError] => Bool
  )
  def call(value, regexp, error = nil)
    if !regexp.match(value)
      error ||= RegexpErr.new(
        t(
          'validator.regexp.error',
          {regexp: regexp.inspect},
          default_by_locale: :en
        )
      )

      raise error
    end

    true
  end
end