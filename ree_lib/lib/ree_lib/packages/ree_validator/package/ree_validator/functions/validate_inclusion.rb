# frozen_string_literal: true

class ReeValidator::ValidateInclusion
  include Ree::FnDSL

  fn :validate_inclusion do
    link :t, from: :ree_i18n

    def_error(:validation) { InclusionErr }
  end

  contract(Any, Or[ArrayOf[Any], SetOf[Any], RangeOf[Any]], Symbol => Bool)
  def call(value, list_or_set, error_code)
    if !list_or_set.include?(value)
      raise InclusionErr.new(
        t('validator.inclusion.error', {list: list_or_set.to_a}, default_by_locale: :en),
        error_code
      )
    end

    true
  end
end