# frozen_string_literal: true

require_relative 'appender'
require 'rollbar'

class ReeLogger::RollbarAppender < ReeLogger::Appender
  include Ree::LinkDSL

  link 'ree_logger/log_event', -> { LogEvent }

  contract(
    Symbol,
    Ksplat[
      access_token: String,
      branch?: Nilor[String],
      host?: Nilor[String],
      environment?: Nilor[String],
      enabled?: Bool,
      request_data?: Nilor[Hash]
    ] =>  Any
  )
  def initialize(level, **rollbar_opts)
    super(
      level, nil
    )

    configure_rollbar(rollbar_opts)
  end


  contract(LogEvent, Nilor[String] => nil)
  def append(event, progname = nil)
    send_event_to_rollbar(event)

    nil
  end

  private

  def send_event_to_rollbar(event)
    rollbar_level = case event.level
                    when :fatal
                      'critical'
                    when :unknown
                      'critical'
                    else
                      event.level.to_s
                    end

    request_data ||= {}
    fingerprint = event.message.to_s

    if event.exception
      fingerprint += event.exception.class.to_s
    end

    fingerprint = Digest::MD5.new.update(fingerprint).to_s
    result = nil

    person_data = { id: request_data["user_id"] }

    Rollbar.scoped(fingerprint: fingerprint, request: request_data, person: person_data) do
      Rollbar.log(
        rollbar_level,
        event.message,
        event.exception,
        event.parameters
      )
    end
  end

  def configure_rollbar(opts)
    Rollbar.configure do |config|
      config.access_token = opts[:access_token]
      config.environment = opts[:environment] if opts[:environment]
      config.enabled = opts[:enabled] if opts[:enabled]
      config.branch = opts[:branch] if opts[:branch]
      config.host = opts[:host] if opts[:host]
    end
  end
end
