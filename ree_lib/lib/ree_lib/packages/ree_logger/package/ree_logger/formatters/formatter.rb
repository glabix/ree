class ReeLogger::Formatter
  def format(event, progname = nil)
    raise NotImplementedError, "should be implemented in derived class"
  end
end