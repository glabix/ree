class ReeDto::DtoBuilder
  include Ree::Contracts::Core
  include Ree::Contracts::ArgContracts
  include Ree::LinkDSL

  link "ree_dto/dto/field_meta", -> { FieldMeta }
  link "ree_dto/dto/collection_meta", -> { CollectionMeta }

  attr_reader :fields, :collections

  def initialize(klass)
    @klass = klass
    @fields = []
    @collections = []
  end

  contract(Symbol, Any, Kwargs[setter: Bool, default: Any] => FieldMeta)
  def field(name, contract, setter: true, default: FieldMeta::NONE)
    existing = @fields.find { _1.name == name }

    if existing
      raise ArgumentError.new("field :#{name} already defined for #{@klass}")
    end

    field = FieldMeta.new(name, contract, setter, default)
    @fields << field
    field
  end

  contract Symbol, Any, Optblock => CollectionMeta
  def collection(name, contract, &proc)
    existing = @collections.find { _1.name == name }

    if existing
      raise ArgumentError.new("collection :#{name} already defined for #{@klass}")
    end

    collection = CollectionMeta.new(name, contract, proc)
    @collections.push(collection)
    collection
  end
end
