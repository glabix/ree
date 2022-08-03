# frozen_string_literal: true

class ReeLogger::Config
  include Ree::BeanDSL

  bean :config do
    singleton
    factory :build

    link :to_obj, from: :ree_object
    link :is_blank, from: :ree_object
    link :validate_inclusion, from: :ree_validator
  end

  LEVELS = %w[warn info debug error fatal unknown].freeze
  RATE_LIMIT_INTERVAL = 60
  RATE_LIMIT_MAX_COUNT = 600

  def build
    to_obj({
      file_path: ENV['LOG_FILE_PATH'],
      file_auto_flush: parse_bool_string(ENV['LOG_FILE_AUTO_FLUSH']),
      levels: {
        file: parse_level(ENV['LOG_LEVEL_FILE']),
        stdout: parse_level(ENV['LOG_LEVEL_STDOUT']),
        rollbar: parse_level(ENV['LOG_LEVEL_ROLLBAR'])
      },
      rollbar: {
        access_token: ENV['ROLLBAR_ACCESS_TOKEN'],
        branch: ENV['ROLLBAR_BRANCH'],
        host: ENV['ROLLBAR_HOST'],
        environment: ENV['ROLLBAR_ENVIRONMENT'],
        enabled: parse_bool_string(ENV['ROLLBAR_ENABLED'])
      },
      rate_limit: {
        interval: get_int_value('LOG_RATE_LIMIT_INTERVAL', RATE_LIMIT_INTERVAL),
        max_count: get_int_value('LOG_RATE_LIMIT_MAX_COUNT', RATE_LIMIT_MAX_COUNT),
      },
      default_filter_words: %w[
        password token credential bearer authorization
      ]
    })
  end

  private

  def get_int_value(name, default)
    value = ENV[name]

    v = if value.to_s.strip.empty?
      default
    else
      Integer(value)
    end

    if v < 0
      raise ArgumentError, "ENV['#{name}'] should be > 0"
    end

    v
  end

  def parse_bool_string(bool)
    return false if is_blank(bool)
    return bool.to_s.downcase == "true"
  end

  def parse_level(level)
    return if is_blank(level)
    validate_inclusion(level, LEVELS)
    level.to_sym
  end
end