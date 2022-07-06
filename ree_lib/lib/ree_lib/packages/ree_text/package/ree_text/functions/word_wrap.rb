# frozen_string_literal: true

class ReeText::WordWrap
  include Ree::FnDSL

  fn :word_wrap 

  DEFAULTS = {
    line_width: 80,
    break_sequence: "\n"
  }

  doc(<<~DOC)
    Wraps the +text+ into lines no longer than +line_width+ width. This method
    breaks on the first whitespace character that does not exceed +line_width+
    (which is 80 by default).
    
      word_wrap('Once upon a time')
      # => Once upon a time
    
      word_wrap('Once upon a time, in a kingdom called Far Far Away, a king fell ill, and finding a successor to the throne turned out to be more trouble than anyone could have imagined...')
      # => Once upon a time, in a kingdom called Far Far Away, a king fell ill, and finding\na successor to the throne turned out to be more trouble than anyone could have\nimagined...
    
      word_wrap('Once upon a time', line_width: 8)
      # => Once\nupon a\ntime
    
      word_wrap('Once upon a time', line_width: 1)
      # => Once\nupon\na\ntime
    
      You can also specify a custom +break_sequence+ ("\n" by default)
    
      word_wrap('Once upon a time', line_width: 1, break_sequence: "\r\n")
      # => Once\r\nupon\r\na\r\ntime
  DOC
  
  contract(
    String,
    Ksplat[
      line_width?: Integer,
      break_sequence?: String
    ] => String
  )
  def call(text, **opts)
    options = DEFAULTS.merge(opts)
    formated_text = text.dup

    formated_text.split("\n").collect do |line|
      if line.length > options[:line_width]
        line
          .gsub(/(.{1,#{options[:line_width]}})(\s+|$)/, "\\1#{options[:break_sequence]}")
          .rstrip
      else
        line
      end
    end * options[:break_sequence]
  end
end