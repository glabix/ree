# frozen_string_literal: true

class ReeValidator::ValidatePassword
  include Ree::FnDSL

  fn :validate_password do
    link :validate_length
    link :t, from: :ree_i18n
  end

  DEFAULTS = {
    min: 1,
    digit_count: 0,
    lowercase_char_count: 0,
    uppercase_char_count: 0,
    special_symbol_count: 0
  }

  PasswordErr = Class.new(StandardError)

  doc(<<~DOC)
    Validates password with selected rules:
      - min length
      - max length
      - min lowercase character
      - min uppercase character
      - min special symbol count
      - min digit count

    Examples of usage:
      validate_password('Password1!') #=> true
      validate_password('Password1!, digit_count: 3) #=> false
      validate_password('Pass1!, lowercase_chars_count: 3) #=> true
      validate_password('Password1!, uppercase_chars_count: 3) #=> false
      validate_password('Password1!$%, special_symbols_count: 3) #=> true
  DOC

  contract(
    String,
    Nilor[Or[SubclassOf[StandardError], StandardError]],
    Ksplat[
      min?: Integer,
      max?: Integer,
      digit_count?: Integer,
      lowercase_char_count?: Integer,
      uppercase_char_count?: Integer,
      special_symbol_count?: Integer
    ] => Bool
  )
  def call(password, error = nil, **opts)
    opts = DEFAULTS.merge(opts)

    if opts[:max]
      validate_length(
        password,
        error ||= PasswordErr.new(
          t("validator.password.max_password_length",
            {number: opts[:max]},
            default_by_locale: :en)
        ),
        max: opts[:max]
      )
    end

    validate_length(
      password,
      error || PasswordErr.new(
        t("validator.password.min_password_length",
          {number: opts[:min]},
          default_by_locale: :en)
      ),
      min: opts[:min]
    )

    if !password.match?(/\A(?=.*\d{#{opts[:digit_count]},})/x)
      error ||= PasswordErr.new(
        t("validator.password.wrong_number_of_digits",
        {number: opts[:digit_count]},
        default_by_locale: :en)
      )
      raise error
    end

    if !password.match?(/\A(?=.*[a-z]{#{opts[:lowercase_char_count]},})/x)
      error ||= PasswordErr.new(
        t("validator.password.wrong_number_of_lowercase_chars",
        {number: opts[:lowercase_char_count]},
        default_by_locale: :en)
      )
      raise error
    end

    if !password.match?(/\A(?=.*[A-Z]{#{opts[:uppercase_char_count]},})/x)
      error ||= PasswordErr.new(
        t("validator.password.wrong_number_of_uppercase_chars",
        {number: opts[:uppercase_char_count]},
        default_by_locale: :en)
      )
      raise error
    end

    if !password.match?(/\A(?=.*[[:^alnum:]]{#{opts[:special_symbol_count]},})/x)
      error ||= PasswordErr.new(
        t("validator.password.wrong_number_of_special_symbols",
        {number: opts[:special_symbol_count]},
        default_by_locale: :en)
      )
      raise error
    end

    true
  end
end