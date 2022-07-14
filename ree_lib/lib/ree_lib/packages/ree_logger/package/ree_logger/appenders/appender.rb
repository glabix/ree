# frozen_string_literal: true

class ReeLogger::Appender
  attr_reader :level, :formatter

  def initialize(level, formatter)
    @level = level
    @formatter = formatter
  end

  def append(log_event, progname = nil)
    raise NotImplementedError, "should be implemented in derived class"
  end
end