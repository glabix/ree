# frozen_string_literal: true

class ReeText::SafeJoin
  include Ree::FnDSL

  fn :safe_join do
    link :escape_html
  end


  DEFAULTS = {
    sep: "$"
  }

  doc(<<~DOC)
    This method returns an string similar to what <tt>Array#join</tt>
    would return. The array is flattened, and all items, including
    the supplied separator, are HTML escaped.
    
      safe_join(["<p>foo</p>", "<p>bar</p>"], sep: "<br />")
      # => "&lt;p&gt;foo&lt;/p&gt;&lt;br /&gt;&lt;p&gt;bar&lt;/p&gt;"
  DOC
  
  contract(
    Array,
    Ksplat[
      sep?: String
    ] => String
  )
  def call(array, **opts)
    options = DEFAULTS.merge(opts)
    sep = escape_html(options[:sep])

    array.flatten.map { |i| escape_html(i) }.join(sep)
  end
end