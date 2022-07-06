# frozen_string_literal: true

class ReeValidator::ValidateLength
  include Ree::FnDSL

  fn :validate_length do
    link :t, from: :ree_i18n

    def_error(:validation) { MinLengthErr }
    def_error(:validation) { MaxLengthErr }
    def_error(:validation) { EqualToLengthErr }
    def_error(:validation) { NotEqualToLengthErr }
  end

  contract(
    -> { _1.respond_to?(:length) },
    Symbol,
    Ksplat[
      min?: Integer,
      max?: Integer,
      equal_to?: Integer,
      not_equal_to?: Integer,
    ] => Bool
    ).throws(MinLengthErr, MaxLengthErr, EqualToLengthErr, NotEqualToLengthErr)
  def call(object, error_code, **opts)
    errors = []
    min, max, equal_to, not_equal_to = opts.values_at(:min, :max, :equal_to, :not_equal_to)

    if min && object.length < min
      raise MinLengthErr.new(
        t('validator.length.can_not_be_less_than', {length: min}, default_by_locale: :en),
        error_code
      )
    end

    if max && object.length > max
      raise MaxLengthErr.new(
        t('validator.length.can_not_be_more_than', {length: max}, default_by_locale: :en),
        error_code
      )
    end

    if equal_to && object.length != equal_to
      raise EqualToLengthErr.new(
        t('validator.length.should_be_equal_to', {length: equal_to}, default_by_locale: :en),
        error_code
      )
    end

    if not_equal_to && object.length == not_equal_to
      raise NotEqualToLengthErr.new(
        t('validator.length.should_not_be_equal_to', {length: not_equal_to}, default_by_locale: :en),
        error_code
      )
    end

    true
  end
end