# frozen_string_literal: true

class ReeText::Highlight
  include Ree::FnDSL

  fn :highlight do
    link :sanitize_html
  end

  DEFAULTS = {
    highlighter: '<mark>\1</mark>',
    sanitize: true,
  }.freeze
  
  doc(<<~DOC)
    Highlights one or more +phrases+ everywhere in +text+ by inserting it into
    a <tt>:highlighter</tt> string. The highlighter can be specialized by passing <tt>:highlighter</tt>
    as a single-quoted string with <tt>\1</tt> where the phrase is to be inserted (defaults to
    <tt><mark>\1</mark></tt>) or passing a block that receives each matched term. By default +text+
    is sanitized to prevent possible XSS attacks.If the input is trustworthy, passing false
    for <tt>:sanitize</tt> will turn sanitizing off.

      highlight('You searched for: rails', 'rails')
      # => You searched for: <mark>rails</mark>
    
      highlight('You searched for: rails', /for|rails/)
      # => You searched <mark>for</mark>: <mark>rails</mark>
    
      highlight('You searched for: ruby, rails, dhh', 'actionpack')
      # => You searched for: ruby, rails, dhh
    
      highlight('You searched for: rails', ['for', 'rails'], highlighter: '<em>\1</em>')
      # => You searched <em>for</em>: <em>rails</em>
    
      highlight('You searched for: rails', 'rails', highlighter: '<a href="search?q=\1">\1</a>')
      # => You searched for: <a href="search?q=rails">rails</a>
    
      highlight('You searched for: rails', 'rails') { |match| link_to(search_path(q: match, match)) }
      # => You searched for: <a href="search?q=rails">rails</a>
    
      highlight('<a href="javascript:alert(\'no!\')">ruby</a> on rails', 'rails', sanitize: false)
      # => <a href="javascript:alert('no!')">ruby</a> on <mark>rails</mark>
  DOC
  
  contract(
    String, 
    Nilor[String, ArrayOf[String], Regexp],
    Ksplat[
      highlighter?: String,
      sanitize?: Bool
    ],
    Optblock => String
  )
  def call(text, phrases = nil, **opts, &block)
    options = DEFAULTS.merge(opts)

    text = sanitize_html(text) if options[:sanitize]

    if !phrases
      text
    else
      match = Array(phrases).map do |p|
        Regexp === p ? p.to_s : Regexp.escape(p)
      end.join("|")

      if block_given?
        text.gsub(/(#{match})(?![^<]*?>)/i, &block)
      else
        highlighter = options[:highlighter]
        text.gsub(/(#{match})(?![^<]*?>)/i, highlighter)
      end
    end
  end
end