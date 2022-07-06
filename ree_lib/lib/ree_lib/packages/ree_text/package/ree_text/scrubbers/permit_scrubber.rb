# frozen_string_literal: true

require 'set'

class ReeText::PermitScrubber < Loofah::Scrubber
  attr_reader :tags, :attributes, :prune

  contract Kwargs[
    prune: Bool,
    tags: Set,
    attributes: Set,
  ] => Any
  def initialize(prune: false, tags: nil, attributes: nil)
    @unescape_html = ReeText::UnescapeHtml.new
    @prune = prune
    @direction = @prune ? :top_down : :bottom_up
    @tags = tags
    @attributes = attributes
  end

  contract Any => Any
  def scrub(node)
    if node.cdata?
      text = node.document.create_text_node(node.text)
      node.replace(text)

      return CONTINUE
    end
    
    return CONTINUE if node.text?

    unless (node.element? || node.comment?) && allowed_node?(node)
      return STOP if scrub_node(node) == STOP
    end

    scrub_attributes(node)
  end

  protected
  
  def allowed_node?(node)
    @tags.include?(node.name)
  end

  def scrub_node(node)
    node.before(node.children) unless prune # strip
    node.remove
  end

  def scrub_attributes(node)
    node.attribute_nodes.each do |attr|
      attr.remove if !@attributes.include?(attr.name)
      scrub_attribute(node, attr)
    end

    scrub_css_attribute(node)
  end

  def scrub_css_attribute(node)
    if Loofah::HTML5::Scrub.respond_to?(:scrub_css_attribute)
      Loofah::HTML5::Scrub.scrub_css_attribute(node)
    else
      style = node.attributes['style']
      style.value = Loofah::HTML5::Scrub.scrub_css(style.value) if style
    end
  end

  def scrub_attribute(node, attr_node)
    attr_name = if attr_node.namespace
      "#{attr_node.namespace.prefix}:#{attr_node.node_name}"
    else
      attr_node.node_name
    end

    if Loofah::HTML5::SafeList::ATTR_VAL_IS_URI.include?(attr_name)
      # this block lifted nearly verbatim from HTML5 sanitization
      val_unescaped = @unescape_html
        .call(attr_node.value)
        .gsub(Loofah::HTML5::Scrub::CONTROL_CHARACTERS,'')
        .downcase

      if val_unescaped =~ /^[a-z0-9][-+.a-z0-9]*:/ && !Loofah::HTML5::SafeList::ALLOWED_PROTOCOLS.include?(val_unescaped.split(Loofah::HTML5::SafeList::PROTOCOL_SEPARATOR)[0])
        attr_node.remove
      end
    end

    if Loofah::HTML5::SafeList::SVG_ATTR_VAL_ALLOWS_REF.include?(attr_name)
      attr_node.value = attr_node.value.gsub(/url\s*\(\s*[^#\s][^)]+?\)/m, ' ') if attr_node.value
    end

    if Loofah::HTML5::SafeList::SVG_ALLOW_LOCAL_HREF.include?(node.name) && attr_name == 'xlink:href' && attr_node.value =~ /^\s*[^#\s].*/m
      attr_node.remove
    end

    if attr_name == 'src' && attr_node.value !~ /[^[:space:]]/
      node.remove_attribute(attr_node.name)
    end

    Loofah::HTML5::Scrub.force_correct_attribute_escaping!(node)
  end
end