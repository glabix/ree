# frozen_string_literal: true

class ReeString::Indent
  include Ree::FnDSL

  fn :indent

  doc(<<~DOC)
    Indents the lines in the receiver:
    
      string = 
      def some_method
        some_code
      end
      indent(string, 2)
      # =>
        def some_method
          some_code
        end
    
    The second argument, +indent_string+, specifies which indent string to
    use. The default is +nil+, which tells the method to make a guess by
    peeking at the first indented line, and fallback to a space if there is
    none.
    
      indent("  foo", 2)              # => "    foo"
      indent("foo\n\t\tbar", 2, "\t") # => "\t\tfoo\n\t\t\t\tbar"
      indent("foo", 2, "\t")          # => "\t\tfoo"
    
    While +indent_string+ is typically one space or tab, it may be any string.
    
    The third argument, +empty_lines+, is a flag that says whether
    empty lines should be indented. Default is false.
    
      indent("foo\n\nbar", 2)                    # => "  foo\n\n  bar"
      indent("foo\n\nbar", 2, empty_lines: true) # => "  foo\n  \n  bar"
  DOC
  contract(
    String,
    Integer,
    Ksplat[
      indent_string?: String,
      empty_lines?: Bool
    ] => String
  )
  def call(string, amount, **opts)
    indent_string = opts[:indent_string] || string[/^[ \t]/] || " "
    regex = opts[:empty_lines] ? /^/ : /^(?!$)/
    string.gsub(regex, indent_string * amount)
  end
end