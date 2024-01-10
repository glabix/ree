# frozen_string_literal: true

class Ree::ObjectLink
  attr_reader :object_name, :package_name, :as, :constants

  # @param [Symbol] object_name Linked object name
  # @param [Symbol] package_name Linked object package
  # @param [Symbol] as Linked object alias name
  def initialize(object_name, package_name, as)
    @object_name = object_name
    @package_name = package_name
    @as = as
    @constants = []
  end

  # @param [ArrayOf[String]]
  # @return [ArrayOf[String]]
  def set_constants(const_list)
    @constants = const_list
  end
end