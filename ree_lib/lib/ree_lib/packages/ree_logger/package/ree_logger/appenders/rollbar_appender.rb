# frozen_string_literal: true

require_relative 'appender'
require 'rollbar'
require 'digest'

class ReeLogger::RollbarAppender < ReeLogger::Appender
  include Ree::LinkDSL

  link 'ree_logger/log_event', -> { LogEvent }

  contract(
    Symbol,
    Kwargs[
      access_token: String,
      environment: String,
    ],
    Ksplat[
      branch?: Nilor[String],
      host?: Nilor[String],
    ] =>  Any
  )
  def initialize(level, access_token:, environment:, **opts)
    super(level, nil)

    Rollbar.configure do |config|
      config.enabled = true
      config.access_token = access_token
      config.environment = environment
      config.branch = opts[:branch] if opts[:branch]
      config.host = opts[:host] if opts[:host]
    end
  end

  contract(LogEvent, Nilor[String] => nil)
  def append(event, progname = nil)
    rollbar_level =
      case event.level
      when :fatal
        'critical'
      when :unknown
        'critical'
      else
        event.level.to_s
      end

    fingerprint = event.message.to_s

    if event.exception
      fingerprint += event.exception.class.to_s
    end

    scope = {}
    parameters = event.parameters.dup

    if parameters.key?(:rollbar_scope) && parameters[:rollbar_scope].is_a?(Hash)
      scope = scope.merge(
        parameters.delete(:rollbar_scope)
      )
    end

    if !scope[:fingerprint]
      fingerprint = event.message.to_s

      if event.exception
        fingerprint += event.exception.class.to_s
      end

      scope[:fingerprint] = Digest::MD5.new.update(fingerprint).to_s
    end

    Rollbar.scoped(scope) do
      Rollbar.log(rollbar_level, event.message, event.exception, parameters)
    end

    nil
  end
end
