# frozen_string_literal: true

class ReeText::TextOnlyScrubber < Loofah::Scrubber
  def initialize
    @direction = :bottom_up
  end

  def scrub(node)
    if node.text?
      CONTINUE
    else
      node.before node.children
      node.remove
    end
  end
end