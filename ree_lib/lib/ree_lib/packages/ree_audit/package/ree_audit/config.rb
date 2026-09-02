# frozen_string_literal: true

class ReeAudit::Config
  include Ree::BeanDSL

  bean :config do
    singleton
    factory :build

    link :to_obj, from: :ree_object
    link :is_blank, from: :ree_object
  end

  MAX_PARAMS_BYTES = 4096
  MAX_PARAMS_DEPTH = 4

  # Blacklist of the framework layer: it protects any host application from
  # leaking a credential into the audit trail. Applications are expected to add
  # their own whitelist on top of it inside their sink.
  DEFAULT_FILTER_WORDS = %w[
    password token credential bearer authorization secret key code email phone
  ].freeze

  def build
    to_obj({
      enabled: parse_bool_string(ENV['AUDIT_ENABLED']),
      max_params_bytes: get_int_value('AUDIT_MAX_PARAMS_BYTES', MAX_PARAMS_BYTES),
      max_params_depth: get_int_value('AUDIT_MAX_PARAMS_DEPTH', MAX_PARAMS_DEPTH),
      filter_words: parse_filter_words(ENV['AUDIT_FILTER_WORDS'])
    })
  end

  private

  def get_int_value(name, default)
    value = ENV[name]

    v = if is_blank(value)
      default
    else
      Integer(value)
    end

    if v <= 0
      raise ArgumentError, "ENV['#{name}'] should be > 0"
    end

    v
  end

  # Audit is opt-in: a host application that knows nothing about this package
  # must not start writing an audit trail after a gem bump.
  def parse_bool_string(bool)
    return false if is_blank(bool)
    bool.to_s.downcase == "true"
  end

  def parse_filter_words(value)
    return DEFAULT_FILTER_WORDS if is_blank(value)
    value.to_s.split(",").map { _1.strip.downcase }.reject(&:empty?)
  end
end
