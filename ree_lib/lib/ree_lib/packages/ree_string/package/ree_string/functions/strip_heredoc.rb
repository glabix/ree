# frozen_string_literal: true

class ReeString::StripHeredoc
  include Ree::FnDSL

  fn :strip_heredoc

  doc(<<~DOC)
    Strips indentation in heredocs.
    
    For example:
    
      puts strip_heredoc(<<-USAGE)
        This command does such and such.
    
        Supported options are:
          -h         This message
          ...
      USAGE
    
    the user would see the usage message aligned against the left margin.
    
    Technically, it looks for the least indented non-empty line
    in the whole string, and removes that amount of leading whitespace.
  DOC
  contract(String => String)
  def call(string)
    string.gsub(/^#{string.scan(/^[ \t]*(?=\S)/).min}/, "").tap do |stripped|
      stripped.freeze if frozen?
    end
  end
end