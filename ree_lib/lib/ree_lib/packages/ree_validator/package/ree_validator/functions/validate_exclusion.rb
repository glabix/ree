# frozen_string_literal: true

class ReeValidator::ValidateExclusion
  include Ree::FnDSL

  fn :validate_exclusion do
    link :t, from: :ree_i18n
  end

  ExclusionErr = Class.new(StandardError)

  contract(
    Any,
    Or[ArrayOf[Any], SetOf[Any], RangeOf[Any]],
    Nilor[StandardError] => Bool
  )
  def call(value, list_or_set, error = nil)
    if list_or_set.include?(value)
      error ||= ExclusionErr.new(
        t(
          'validator.exclusion.error',
          {list: list_or_set.to_a},
          default_by_locale: :en
        )
      )

      raise error
    end

    true
  end
end