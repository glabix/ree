# frozen_string_literal: true

module ReeDto::DSL
  def self.included(base)
    base.include Ree::LinkDSL
    base.link :build_dto, from: :ree_dto
  end
end