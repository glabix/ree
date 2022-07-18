# frozen_string_literal: true

class ReeValidator::ValidatePresence
  include Ree::FnDSL

  fn :validate_presence do
    link :is_blank, from: :ree_object
    link :t, from: :ree_i18n
  end

  PresenceErr = Class.new(StandardError)

  contract(
    Any,
    Nilor[StandardError] => Bool
  ).throws(PresenceErr)
  def call(value, error = nil)
    if (is_blank(value))

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