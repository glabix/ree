# frozen_string_literal: true

class ReeString::TruncateWords
  include Ree::FnDSL

  fn :truncate_words

  DEFAULT_OMISSION = "..."

  doc(<<~DOC)
    Truncates a given +text+ after a given number of words (<tt>words_count</tt>):
    
      truncate_words('Once upon a time in a world far far away', 4)
      # => "Once upon a time..."
    
    Pass a string or regexp <tt>:separator</tt> to specify a different separator of words:
    
      truncate_words('Once<br>upon<br>a<br>time<br>in<br>a<br>world', 5, separator: '<br>')
      # => "Once<br>upon<br>a<br>time<br>in..."
    
    The last characters will be replaced with the <tt>:omission</tt> string (defaults to "..."):
    
      truncate_words('And they found that many people were sleeping better.', 5, omission: '... (continued)')
      # => "And they found that many... (continued)"
  DOC
  contract(
    String,
    Integer,
    Ksplat[
      omission?: String,
      separator?: Or[String, Regexp]
    ] => String
  )
  def call(str, words_count, **opts)
    str = str.dup
    sep = opts[:separator] || /\s+/
    sep = Regexp.escape(sep.to_s) unless Regexp === sep

    if str =~ /\A((?>.+?#{sep}){#{words_count - 1}}.+?)#{sep}.*/m
      $1 + (opts[:omission] || "...")
    else
      str
    end
  end
end