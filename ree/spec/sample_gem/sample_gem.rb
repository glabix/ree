# frozen_string_literal: true

require "ree"

module SampleGem
end

Ree.register_gem(
  :sample_gem,
  File.join(__dir__, "sample_gem")
)