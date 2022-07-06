# frozen_string_literal: true

class ReeValidator::ValidateExclusion
  include Ree::FnDSL

  fn :validate_exclusion do
    link :t, from: :ree_i18n

    def_error(:validation) { ExclusionErr }
  end

  contract(Any, Or[ArrayOf[Any], SetOf[Any], RangeOf[Any]], Symbol => Bool)
  def call(value, list_or_set, error_code)
    if list_or_set.include?(value)
      raise ExclusionErr.new(
        t('validator.exclusion.error', {list: list_or_set.to_a}, default_by_locale: :en),
        error_code
      )
    end

    true
  end
end