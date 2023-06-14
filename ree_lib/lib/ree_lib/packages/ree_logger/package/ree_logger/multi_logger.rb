class ReeLogger::MultiLogger < Logger
  include Ree::LinkDSL

  link :to_hash, from: :ree_object
  link :transform_values, from: :ree_hash
  link 'ree_logger/log_event', -> { LogEvent }
  link 'ree_logger/rate_limiter', -> { RateLimiter }

  undef level=
  undef datetime_format
  undef datetime_format=
  undef sev_threshold=

  LEVEL_MAPPING = {
    debug: Logger::DEBUG,
    info: Logger::INFO,
    warn: Logger::WARN,
    error: Logger::ERROR,
    fatal: Logger::FATAL,
    unknown: Logger::UNKNOWN
  }

  attr_reader :appenders, :silenced, :progname

  contract(
    Nilor[String],
    Nilor[RateLimiter],
    Nilor[ArrayOf[String]] => Any
  ).throws(ArgumentError)
  def initialize(progname, rate_limiter, filter_words)
    @progname = progname
    @rate_limiter = rate_limiter
    @filter_words = filter_words || []
    @appenders = []
    @silenced  = false
  end

  def add_appender(appender)
    @appenders.push(appender)
  end

  contract Optblock => Bool
  def silence(&block)
    if block_given?
      @silenced = true
      block.call
      unsilence
    else
      @silenced = true
    end

    @silenced
  end

  contract None => Bool
  def unsilence
    @silenced = false
  end

  contract(Nilor[String], Hash, Nilor[Exception], Bool, Nilor[String], Optblock => nil)
  def debug(message = nil, parameters = {}, exception = nil, log_args = false, progname = nil, &block)
    if block_given?
      log_block(:debug, parameters, log_args, yield)
    else
      msg = get_message(message)
      log(:debug, msg, parameters, nil, log_args)
    end
  end

  contract(Nilor[String], Hash, Nilor[Exception], Bool, Nilor[String], Optblock => nil)
  def info(message = nil, parameters = {}, exception = nil, log_args = false, progname = nil, &block)
    if block_given?
      log_block(:info, parameters, log_args, yield)
    else
      msg = get_message(message)
      log(:info, msg, parameters, nil)
    end
  end

  contract(Nilor[String], Hash, Nilor[Exception], Bool, Nilor[String], Optblock => nil)
  def warn(message = nil, parameters = {}, exception = nil, log_args = false, progname = nil, &block)
    if block_given?
      log_block(:warn, parameters, log_args, yield)
    else
      msg = get_message(message)
      log(:warn, msg, parameters, nil)
    end
  end

  contract(Nilor[String], Hash, Nilor[Exception], Bool, Nilor[String], Optblock => nil)
  def error(message = nil, parameters = {}, exception = nil, log_args = true, progname = nil,  &block)
    if block_given?
      log_block(:error, parameters, log_args, yield)
    else
      msg = get_message(message)
      log(:error, msg, parameters, exception, log_args)
    end
  end

  contract(Nilor[String], Hash, Nilor[Exception], Bool, Nilor[String], Optblock => nil)
  def fatal(message = nil, parameters = {}, exception = nil, log_args = true, progname = nil, &block)
    if block_given?
      log_block(:fatal, parameters, log_args, yield)
    else
      msg = get_message(message)
      log(:fatal, msg, parameters, exception, log_args)
    end
  end

  contract(Nilor[String], Hash, Nilor[Exception], Bool, Nilor[String], Optblock => nil)
  def unknown(message = nil, parameters = {}, exception = nil, log_args = true, progname = nil,  &block)
    if block_given?
      log_block(:unknown, parameters, log_args, yield)
    else
      msg = get_message(message)
      log(:unknown, msg, parameters, exception, log_args)
    end
  end

  contract(Symbol, Hash, Bool, Or[Hash, String] => nil)
  def log_block(error, parameters, log_args, block_parameters)
    if block_parameters.is_a?(Hash)
      log(error, "", block_parameters.merge(parameters), nil, log_args)
    else
      log(error, block_parameters, parameters, nil, log_args)
    end
  end

  contract(Symbol, String, Hash, Nilor[Exception], Bool => nil)
  def log(level, message, parameters = {}, exception = nil, log_args = false)
    if @rate_limiter
      @rate_limiter.call do
        log_event(level, message, parameters, exception, log_args)
      end
    else
      log_event(level, message, parameters, exception, log_args)
    end

    nil
  end

  alias_method :add, :log

  private

  def log_event(level, message, parameters, exception, log_args)
    return if @silenced if ![:error, :fatal].include?(level)

    if log_args
      begin
        method_binding = binding.of_caller(2)
        method_name = method_binding.eval('__method__')
        obj = method_binding.eval('self')

        args = {}

        obj.method(method_name).parameters.each do |_, name|
          args[name] = method_binding.local_variable_get(name)
        end

        args = transform_values(to_hash(args)) do |k, v|
          if @filter_words.any? { k.to_s.include?(_1) }
            'FILTERED'
          else
            v
          end
        end

        parameters[:method] = {}
        parameters[:method][:name] = method_name
        parameters[:method][:args] = args
      rescue
      end
    end

    parameters = transform_values(parameters) do |k, v|
      if @filter_words.any? { k.to_s.include?(_1) }
        'FILTERED'
      else
        v
      end
    end

    event = LogEvent.new(level, message, exception, parameters)

    appenders.each do |appender|
      if higher_or_equal_level?(event.level, appender.level)
        begin
          appender.append(event, @progname)
        rescue
          # fail silently if logger is not working by some reason
        end
      end
    end
  end

  def higher_or_equal_level?(message_level, appender_level)
    LEVEL_MAPPING[message_level] >= LEVEL_MAPPING[appender_level]
  end

  def get_message(message)
    message || (raise ArgumentError.new("message should be given"))
  end
end