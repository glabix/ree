# frozen_string_literal: true

require_relative "ree_lib/version"
require "ree"

module ReeLib
end

Ree.register_gem(:ree_lib, File.join(__dir__, "ree_lib"))