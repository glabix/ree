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
    Nilor[SubclassOf[StandardError]] => Bool
  )
  def call(value, regexp, error = nil)
    if !regexp.match(value)
      klass = error || RegexpErr

      raise klass.new(
        t(
          'validator.regexp.error',
          {regexp: regexp.inspect},
          default_by_locale: :en
        )
      )
    end

    true
  end
end