# frozen_string_literal: true

module ReeAudit
  include Ree::PackageDSL

  package do
    depends_on :ree_object
    depends_on :ree_hash
    depends_on :ree_datetime
    depends_on :ree_logger
    depends_on :ree_errors

    env_var 'AUDIT_ENABLED'
    env_var 'AUDIT_MAX_PARAMS_BYTES'
    env_var 'AUDIT_MAX_PARAMS_DEPTH'
    env_var 'AUDIT_FILTER_WORDS'
  end

  class << self
    # Attaches application-level facts to the call currently being audited:
    # which permission was checked, which object was opened, whose data it is.
    #
    # Returns nil when there is nothing to annotate — audit is disabled, or the
    # code was reached from outside an audited route. Product code calls this
    # through the `annotate_audit` fn, never through the constant directly, so
    # that removing `depends_on :ree_audit` fails loudly instead of in
    # production.
    def annotate(**attrs)
      event = Context.current
      return nil if event.nil?

      event.annotations.merge!(attrs)
    end
  end
end

require_relative "ree_audit/context"
