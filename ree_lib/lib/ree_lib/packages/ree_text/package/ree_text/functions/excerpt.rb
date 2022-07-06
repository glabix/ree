# frozen_string_literal: true

class ReeText::Excerpt
  include Ree::FnDSL

  fn :excerpt do
    link :is_blank, from: :ree_object
  end

  DEFAULTS = {
    radius: 100,
    omission: "...",
    separator: ""
  }

  doc(<<~DOC)
    Extracts an excerpt from +text+ that matches the first instance of +phrase+.
    The <tt>:radius</tt> option expands the excerpt on each side of the first occurrence of +phrase+ by the number of characters
    defined in <tt>:radius</tt> (which defaults to 100). If the excerpt radius overflows the beginning or end of the +text+,
    then the <tt>:omission</tt> option (which defaults to "...") will be prepended/appended accordingly. Use the
    <tt>:separator</tt> option to choose the delimitation. The resulting string will be stripped in any case. If the +phrase+
    isn't found, +nil+ is returned.
    
      excerpt('This is an example', 'an', radius: 5)
      # => ...s is an exam...
    
      excerpt('This is an example', 'is', radius: 5)
      # => This is a...
    
      excerpt('This is an example', 'is')
      # => This is an example
    
      excerpt('This next thing is an example', 'ex', radius: 2)
      # => ...next...
    
      excerpt('This is also an example', 'an', radius: 8, omission: '<chop> ')
      # => <chop> is also an example
    
      excerpt('This is a very beautiful morning', 'very', separator: ' ', radius: 1)
      # => ...a very beautiful...
  DOC
  
  contract(
    String,
    Or[String, Regexp],
    Ksplat[
      radius?: Integer,
      omission?: String,
      separator?: String
    ] => String
  )
  def call(text, phrase, **opts)
    options = DEFAULTS.merge(opts)
    
    return if is_blank(text) && is_blank(phrase)

    separator = options[:separator]

    case phrase
    when Regexp
      regex = phrase
    else
      regex = /#{Regexp.escape(phrase)}/i
    end

    return unless matches = text.match(regex)
    phrase = matches[0]

    unless is_blank(separator)
      text.split(separator).each do |value|
        if value.match?(regex)
          phrase = value
          break
        end
      end
    end

    first_part, second_part = text.split(phrase, 2)

    prefix, first_part   = cut_excerpt_part(:first, first_part, separator, options)
    postfix, second_part = cut_excerpt_part(:second, second_part, separator, options)

    affix = [first_part, separator, phrase, separator, second_part].join.strip
    [prefix, affix, postfix].join
  end

  private

  def cut_excerpt_part(part_position, part, separator, options)
    return "", "" unless part

    radius = options[:radius]
    omission = options[:omission]

    if separator != ""
      part = part.split(separator)
      part.delete("")
    end

    affix = part.length > radius ? omission : ""

    part = if part_position == :first
      last(part, radius)
    else
      first(part, radius)
    end

    if separator != ""
      part = part.join(separator)
    end

    return affix, part
  end

  def first(string, limit = 1)
    string[0, limit] || raise(ArgumentError, "negative limit")
  end

  def last(string, limit = 1)
    string[[string.length - limit, 0].max, limit] || raise(ArgumentError, "negative limit")
  end
end