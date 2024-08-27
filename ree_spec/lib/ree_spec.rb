# frozen_string_literal: true

require_relative "ree_spec/version"
require "ree"

module ReeSpec
end

Ree.register_gem(:ree_spec, File.join(__dir__, "ree_spec"))