# frozen_string_literal: true

class ReeMapper::ErrorWithLocation < ReeMapper::Error
  attr_accessor :location

  contract(String, String, ArrayOf[String]  => Any)
  def initialize(message, location = nil, field_name_parts = [])
    @message = message
    @location = location
    @field_name_parts = field_name_parts
  end

  contract(String => nil)
  def prepend_field_name(part)
    @field_name_parts.unshift part
    nil
  end

  contract(None => Nilor[String])
  def field_name
    @field_name_parts.reduce { "#{_1}[#{_2}]" }
  end

  if ENV["RUBY_ENV"] == "test"

    contract(None => String)
    def message
      msg = @message

      if location
        msg = "#{msg}, located at #{location}"
      end

      return msg if @field_name_parts.empty?

      "`#{field_name}` #{msg}"
    end

  else

    def message
      return @message if @field_name_parts.empty?

      "`#{field_name}` #{@message}"
    end

    def full_message(...)
      msg = super
      return msg if location.nil?

      last_sym_idx = msg.index(/\).*\n/)
      return msg if last_sym_idx.nil?

      msg.insert(last_sym_idx + 1, ", located at #{location}")
    end

  end
end
