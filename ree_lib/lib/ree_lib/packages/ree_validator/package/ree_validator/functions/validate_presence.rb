# frozen_string_literal: true

class ReeValidator::ValidatePresence
  include Ree::FnDSL

  fn :validate_presence do
    link :t, from: :ree_i18n
  end

  PresenceErr = Class.new(StandardError)

  contract(
    Any,
    Nilor[StandardError] => Bool
  ).throws(PresenceErr)
  def call(value, error = nil)
    if (value.nil? ||
      (value.is_a?(String) && value.strip.length == 0) ||
      (value.is_a?(Array) && value.size == 0) ||
      (value.is_a?(Hash) && value.size == 0) ||
      (value.is_a?(Set) && value.size == 0))

      error ||= PresenceErr.new(
        t(
          'validator.presence.can_not_be_blank',
          default_by_locale: :en
        )
      )

      raise error
    end

    true
  end
end