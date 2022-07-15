require_relative 'formatter'

class ReeLogger::ColorizedFormatter < ReeLogger::Formatter
  include Ree::BeanDSL

  bean :colorized_formatter do
    link 'ree_logger/log_event', -> { LogEvent }
    link :not_blank, from: :ree_object
    link :now, from: :ree_datetime
  end

  contract LogEvent, Nilor[String] => String
  def format(event, progname = nil)
    prefix = if progname
      "[#{progname}] "
    else
      ""
    end

    level = "%-5s" % "#{event.level.to_s}:"
    level = colorize_by_level(level, event.level)
    out = "#{prefix}%-6s %s" % ["[#{now.strftime("%d/%m/%y %H:%M:%S")}]", colorize_message(level, event.message)]

    if not_blank(event.parameters)
      out += "#{prefix}\n#{colorize_blue('PARAMETERS:')} #{event.parameters}"
    end

    if event.exception
      backtrace = (event.exception.backtrace || []).join("\n")
      out += "#{prefix}\n#{colorize_red('EXCEPTION:')} #{event.exception.class} (#{event.exception.message})\n#{backtrace}"
    end

    out
  end

  private

  def colorize_message(level, message)
    if message =~ /(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)/
      level = "\n\n#{level}"
      message = colorize_blue(message)
    elsif message =~ /Parameters: /
      message = message.gsub("Parameters:", colorize_blue("Parameters:"))
    elsif message =~ /SELECT/
      message = message.gsub("SELECT", colorize_green("SELECT"))
    elsif message =~ /(INSERT|UPDATE|DELETE)/
      message = message.gsub($1, colorize_red($1))
    end

    "#{level} #{message}"
  end

  def colorize_by_level(string, level)
    out = Rainbow(string)
    case level
    when :info
      out.cyan
    when :debug
      out.yellow
    when :warn
      out.yellow
    when :error
      out.red
    when :fatal
      out.red
    else
      out.red
    end
  end

  def colorize_green(string)
    Rainbow(string).green
  end

  def colorize_blue(string)
    Rainbow(string).blue
  end

  def colorize_red(string)
    Rainbow(string).red
  end
end