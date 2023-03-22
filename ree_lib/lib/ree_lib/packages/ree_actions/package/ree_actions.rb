# frozen_string_literal: true

module ReeActions
  include Ree::PackageDSL

  package do
    depends_on :ree_mapper
  end
end

require_relative "ree_actions/dsl"