class ReeLogger::LogEvent < Struct.new(:level, :message, :exception, :parameters)
end
