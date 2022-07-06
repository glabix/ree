# frozen_string_literal: true

module Ree::Contracts
  module Utils
    def self.eigenclass_of(target)
      class << target; self; end
    end
  end
end
