# frozen_string_literal: true

module Ree::Contracts
  module Core
    def self.included(base)
      common(base)
    end

    def self.extended(base)
      common(base)
    end

    def self.common(base)
      base.extend(Contractable)
    end
  end
end
