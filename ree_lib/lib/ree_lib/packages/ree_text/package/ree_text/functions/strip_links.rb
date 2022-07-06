# frozen_string_literal: true

class ReeText::StripLinks
  include Ree::FnDSL

  fn :strip_links do
    link 'ree_text/scrubbers/target_scrubber', -> { TargetScrubber }
  end

  DEFAULTS = {
    tags: Set.new(%w(a)),
    attributes: Set.new(%w(href))
  }.freeze

  doc(<<~DOC)
    Removes +a+ tags and +href+ attributes leaving only the link text.
    strip_links('<a href="example.com">Only the link text will be kept.</a>')
    #
    #  => 'Only the link text will be kept.'
  DOC
  
  contract(String => String)
  def call(html)
    link_scrubber = TargetScrubber.new(
      tags: DEFAULTS[:tags],
      attributes: DEFAULTS[:attributes]
    )

    Loofah.scrub_fragment(html, link_scrubber).to_s
  end
end