# frozen_string_literal: true

require 'set'

class ReeText::SanitizeHtml
  include Ree::FnDSL

  fn :sanitize_html do
    link 'ree_text/scrubbers/permit_scrubber', -> { PermitScrubber }
  end

  ALLOWED_TAGS = Set.new(
    %w(
      strong em b i p code pre tt samp kbd var sub
      sup dfn cite big small address hr br div span
      h1 h2 h3 h4 h5 h6 ul ol li dl dt dd abbr
      acronym a img blockquote del ins
    )
  )

  ALLOWED_ATTRIBUTES = Set.new(
    %w(
      href src width height alt cite datetime
      title class name xml:lang abbr
    )
  )

  DEFAULTS = {
    tags: nil,
    attributes: nil
  }

  doc(<<~DOC)
    Sanitizes both html and css via the safe lists found here:
    https://github.com/flavorjones/loofah/blob/master/lib/loofah/html5/safelist.rb

    Tags and attributes can also be passed to +sanitize+.
    Passed options take precedence over the class level options.
  DOC
  
  contract(
    String,
    Kwargs[
      prune: Bool
    ],
    Ksplat[
      tags?: ArrayOf[String],
      attributes?: ArrayOf[String]
    ] => String
  ).throws(ArgumentError)
  def call(html, prune: false, **opts)
    options = DEFAULTS.merge(opts)

    tags = if options[:tags]
      remove_safelist_tag_combinations(Set.new(options[:tags]))
    else
      ALLOWED_TAGS
    end

    attributes = options[:attributes] ? Set.new(options[:attributes]) : ALLOWED_ATTRIBUTES

    loofah_fragment = Loofah.fragment(html)

    permit_scrubber = PermitScrubber.new(
      prune: prune,
      tags: tags, 
      attributes: attributes
    )

    loofah_fragment.scrub!(permit_scrubber)

    properly_encode(loofah_fragment, encoding: 'UTF-8')
  end

  private 

  def properly_encode(fragment, options)
    fragment.xml? ? fragment.to_xml(options) : fragment.to_html(options)
  end

  def remove_safelist_tag_combinations(tags)
    if !loofah_using_html5? && tags.include?("select") && tags.include?("style")
      tags.delete("style")
    end

    tags
  end

  def loofah_using_html5?
    # future-proofing, see https://github.com/flavorjones/loofah/pull/239
    Loofah.respond_to?(:html5_mode?) && Loofah.html5_mode?
  end
end