# frozen_string_literal: true

require_relative 'appender'

class ReeLogger::StdoutAppender < ReeLogger::Appender
  include Ree::LinkDSL

  link 'ree_logger/formatters/colorized_formatter', -> { ColorizedFormatter }
  link 'ree_logger/formatters/formatter', -> { Formatter }

  contract(
    Symbol,
    Nilor[Formatter] =>  Any
  )
  def initialize(level, formatter = nil)
    super(
      level,
      formatter || ColorizedFormatter.new
    )
  end


  contract ReeLogger::LogEvent, Nilor[String] => nil
  def append(event, progname = nil)
    message = @formatter.format(event, progname)
    print(message + "\n")
    STDOUT.flush

    nil
  end
end
