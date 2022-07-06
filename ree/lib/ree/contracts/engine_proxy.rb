# frozen_string_literal: true

module Ree::Contracts
  class EngineProxy
    def initialize(engine)
      @engine = engine
    end

    def throws(*errors)
      @engine.add_errors(*errors)
    end
  end
end
