# frozen_string_literal: true

class ReeString::Truncate
  include Ree::FnDSL

  fn :truncate

  DEFAULT_OMISSION = "..."

  doc(<<~DOC)
    Truncates a given +text+ after a given <tt>length</tt> if +text+ is longer than <tt>length</tt>:
    
      truncate('Once upon a time in a world far far away', 27)
      => "Once upon a time in a wo..."
    
    Pass a string or regexp <tt>:separator</tt> to truncate +text+ at a natural break:
    
      truncate('Once upon a time in a world far far away', 27, separator: ' ')
      => "Once upon a time in a..."
    
      truncate('Once upon a time in a world far far away', 27, separator: /\s/)
      => "Once upon a time in a..."
    
    The last characters will be replaced with the <tt>:omission</tt> string (defaults to "...")
    for a total length not exceeding <tt>length</tt>:
    
      truncate('And they found that many people were sleeping better.', 25, omission: '... (continued)')
      => "And they f... (continued)"
  DOC
  contract(
    String,
    Integer,
    Ksplat[
      omission?: String,
      separator?: Or[String, Regexp]
    ] => String
  )
  def call(str, truncate_at, **opts)
    return str.dup unless str.length > truncate_at

    omission = opts[:omission] || DEFAULT_OMISSION
    length_with_room_for_omission = truncate_at - omission.length
    
    stop = if opts[:separator]
      str.rindex(opts[:separator], length_with_room_for_omission) || length_with_room_for_omission
    else
      length_with_room_for_omission
    end

    +"#{str[0, stop]}#{omission}"
  end
end