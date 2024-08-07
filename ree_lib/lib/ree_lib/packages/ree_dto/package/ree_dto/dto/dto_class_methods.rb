require_relative "./field_meta"
require_relative "./collection_meta"

module ReeDto::DtoClassMethods
  include Ree::Contracts::Core
  include Ree::Contracts::ArgContracts

  contract None => ArrayOf[ReeDto::FieldMeta]
  def fields
    @fields ||= []
  end

  contract None => ArrayOf[ReeDto::CollectionMeta]
  def collections
    @collections ||= []
  end

  private

  def set_fields(v)
    @fields = v
  end

  def set_collections(v)
    @collections = v
  end
end