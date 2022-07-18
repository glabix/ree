require_relative 'formatter'

class ReeLogger::DefaultFormatter < ReeLogger::Formatter
  include Ree::BeanDSL

  bean :default_formatter do
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

    out = "#{prefix}%-6s %s %s" % ["[#{now.strftime("%d/%m/%y %H:%M:%S")}]", "#{event.level.to_s.upcase}:", event.message]

    if not_blank(event.parameters)
      out += "#{prefix}\nPARAMETERS: #{event.parameters}"
    end

    if event.exception
      backtrace = (event.exception.backtrace || []).join("\n")
      out += "#{prefix}\nEXCEPTION: #{event.exception.class} (#{event.exception.message})\n#{backtrace}"
    end

    out
  end
end