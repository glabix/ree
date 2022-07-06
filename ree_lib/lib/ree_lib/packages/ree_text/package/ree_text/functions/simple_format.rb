# frozen_string_literal: true

class ReeText::SimpleFormat
  include Ree::FnDSL

  fn :simple_format do
    link :escape_html
    link :sanitize_html
    link :is_blank, from: :ree_object
    
    link 'ree_text/functions/constants', -> {
      TAG_NAME_START_REGEXP & TAG_NAME_REPLACEMENT_CHAR & TAG_NAME_FOLLOWING_REGEXP
    }
  end

  DEFAULTS = {
    html_options: {},
    wrapper_tag: :p,
    sanitize: false
  }

  doc(<<~DOC)
    Returns +text+ transformed into HTML using simple formatting rules.
    Two or more consecutive newlines (<tt>\n\n</tt> or <tt>\r\n\r\n</tt>) are
    considered a paragraph and wrapped in <tt><p></tt> tags. One newline
    (<tt>\n</tt> or <tt>\r\n</tt>) is considered a linebreak and a
    <tt><br /></tt> tag is appended. This method does not remove the
    newlines from the +text+.
    
    You can pass any HTML attributes into <tt>html_options</tt>. These
    will be added to all created paragraphs.
    
    ==== Options
    * <tt>:sanitize</tt> - If +false+, does not sanitize +text+.
    * <tt>:wrapper_tag</tt> - String representing the wrapper tag, defaults to <tt>"p"</tt>
    
    ==== Examples
      my_text = "Here is some basic text...\n...with a line break."
    
      simple_format(my_text)
      # => "<p>Here is some basic text...\n<br />...with a line break.</p>"
    
      simple_format(my_text, wrapper_tag: "div")
      # => "<div>Here is some basic text...\n<br />...with a line break.</div>"
    
      more_text = "We want to put a paragraph...\n\n...right there."
    
      simple_format(more_text)
      # => "<p>We want to put a paragraph...</p>\n\n<p>...right there.</p>"
    
      simple_format("Look ma! A class!", class: 'description')
      # => "<p class='description'>Look ma! A class!</p>"
    
      simple_format("<blink>Unblinkable.</blink>", sanitize: true)
      # => "<p>Unblinkable.</p>"
    
      simple_format("<blink>Blinkable!</blink> It's true.", sanitize: false)
      # => "<p><blink>Blinkable!</blink> It's true.</p>"
  DOC

  contract(
    Nilor[String],
    Ksplat[
      html_options?: Hash,
      wrapper_tag?: Or[Symbol, String],
      sanitize?: Bool 
    ] => String
  )
  def call(text, **opts)
    options = DEFAULTS.merge(opts)
    text = sanitize_html(text) if options[:sanitize]
    wrapper_tag = options[:wrapper_tag]
    html_options = options[:html_options]
    paragraphs = split_paragraphs(text)

    if is_blank(paragraphs)
      content_tag_string(wrapper_tag, nil, html_options)
    else
      paragraphs
        .map! { content_tag_string(wrapper_tag, _1, html_options) }
        .join("\n\n")
    end
  end

  private 

  def split_paragraphs(text)
    return [] if is_blank(text)

    text
      .dup
      .to_s
      .gsub(/\r\n?/, "\n")
      .split(/\n\n+/)
      .map { _1.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') || _1 }
  end

  def content_tag_string(name, content, html_options, escape = true)
    tag_options = is_blank(html_options) ? nil : tag_options(html_options, escape)
    name = xml_name_escape(name)

    "<#{name}#{tag_options}>#{content}</#{name}>"
  end

  def xml_name_escape(name)
    name = name.to_s
    return "" if is_blank(name)

    starting_char = name[0].gsub(TAG_NAME_START_REGEXP, TAG_NAME_REPLACEMENT_CHAR)
    return starting_char if name.size == 1

    following_chars = name[1..-1].gsub(TAG_NAME_FOLLOWING_REGEXP, TAG_NAME_REPLACEMENT_CHAR)
    starting_char + following_chars
  end

  def tag_options(html_options, escape = true)
    output = +""
    sep = " "

    html_options.each_pair do |key, value|
      output << sep
      output << tag_option(key, value, escape)
    end

    output 
  end

  def tag_option(key, value, escape)
    key = xml_name_escape(key) if escape
    value = escape ? escape_html(value) : value.to_s
    value = value.gsub('"', "&quot;") if value.include?('"')

    %(#{key}="#{value}")
  end
end