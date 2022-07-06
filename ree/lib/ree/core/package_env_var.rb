# frozen_string_literal  = true

class Ree::PackageEnvVar
  attr_reader :name, :doc

  # @param [String] name Env var name
  # @param [Nilor[String]] Env var description
  def initialize(name, doc)
    @name = name
    @doc = doc
  end
end