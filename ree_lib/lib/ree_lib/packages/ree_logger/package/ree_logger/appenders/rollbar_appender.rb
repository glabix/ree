# frozen_string_literal: true

require_relative 'appender'
require 'rollbar'

class ReeLogger::RollbarAppender < ReeLogger::Appender
  include Ree::LinkDSL

  link 'ree_logger/log_event', -> { LogEvent }

  contract(
    Symbol,
    {
      access_token: String,
      branch?: Nilor[String],
      host?: Nilor[String]
    } =>  Any
  )
  def initialize(level, rollbar_opts)
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

    Rollbar.log(
      rollbar_level,
      event.message,
      exception: event.exception,
      parameters: event.parameters
    )
  end

  def configure_rollbar(opts)
    Rollbar.configure do |config|
      config.access_token = opts[:access_token]
      config.branch = opts[:branch] if opts[:branch]
      config.host = opts[:host] if opts[:host]
    end
  end
end
