# frozen_string_literal: true

class ReeText::TargetScrubber < ReeText::PermitScrubber
  def allowed_node?(node)
    !super
  end

  def scrub_attribute?(name)
    !super
  end
end