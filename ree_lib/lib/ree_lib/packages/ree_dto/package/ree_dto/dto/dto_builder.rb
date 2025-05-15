class ReeDto::DtoBuilder
  include Ree::Contracts::Core
  include Ree::Contracts::ArgContracts
  include Ree::LinkDSL

  link "ree_dto/dto/field_meta", -> { FieldMeta }
  link "ree_dto/dto/collection_meta", -> { CollectionMeta }

  attr_reader :fields, :fields_with_default, :collections

  def initialize(klass)
    @klass = klass
    @fields = []
    @fields_with_default = []
    @collections = []
  end

  contract(Symbol, Any, Kwargs[setter: Bool, default: Any, field_type: Symbol] => FieldMeta)
  def field(name, contract, setter: true, default: FieldMeta::NONE, field_type: :custom)
    existing = @fields.find { _1.name == name }

    if existing
      raise ArgumentError.new("field :#{name} already defined for #{@klass}")
    end

    field = FieldMeta.new(name, contract, setter, default, field_type)
    @fields << field
    @fields_with_default << field if field.has_default?
    field
  end

  contract(Symbol, Any, Kwargs[setter: Bool, default: Any] => FieldMeta)
  def column(name, contract, setter: true, default: FieldMeta::NONE)
    field(name, contract, setter: setter, default: default, field_type: :db)
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
