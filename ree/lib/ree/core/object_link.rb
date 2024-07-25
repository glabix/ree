# frozen_string_literal: true

class Ree::ObjectLink
  attr_reader :object_name, :package_name, :as, :constants, :target

  # @param [Symbol] object_name Linked object name
  # @param [Symbol] package_name Linked object package
  # @param [Symbol] as Linked object alias name
  # @param Nilor[Symbol] target Linked object target
  def initialize(object_name, package_name, as, target)
    @object_name = object_name
    @package_name = package_name
    @as = as
    @target = target
    @constants = []
  end

  # @param [ArrayOf[String]]
  # @return [ArrayOf[String]]
  def set_constants(const_list)
    @constants = const_list
  end
end