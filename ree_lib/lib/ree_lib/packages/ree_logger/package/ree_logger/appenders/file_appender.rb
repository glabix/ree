# frozen_string_literal: true

require_relative 'appender'

class ReeLogger::FileAppender < ReeLogger::Appender
  include Ree::LinkDSL

  link 'ree_logger/formatters/default_formatter', -> { DefaultFormatter }
  link 'ree_logger/formatters/formatter', -> { Formatter }

  DEFAULTS = {
    auto_flush: false,
    log_file_count: 10,
    log_file_size: 1048576 # 1.megabyte
  }.freeze

  attr_reader :file, :auto_flush, :logger

  contract(
    Symbol,
    Nilor[Formatter],
    String,
    Ksplat[
      auto_flush?: Bool,
      log_file_count?: Integer,
      log_file_size?: Integer
    ] => Any
  )
  def initialize(level, formatter, file_path, **opts)
    super(
      level,
      formatter || DefaultFormatter.new
    )

    opts = DEFAULTS.merge(opts)

    unless File.exists?(file_path)
      FileUtils.mkdir_p(Pathname.new(file_path).parent.to_s)
      FileUtils.touch(file_path)
    end

    @auto_flush = opts[:auto_flush]
    @file = File.open(file_path, File::WRONLY | File::APPEND)

    @logger = Logger.new(
      @file, opts[:log_file_count], opts[:log_file_size]
    )
  end

  contract(ReeLogger::LogEvent, Nilor[String] => nil)
  def append(event, progname = nil)
    message = @formatter.format(event, progname)
    logger << (message + "\n")
    file.flush if auto_flush

    nil
  end
end
