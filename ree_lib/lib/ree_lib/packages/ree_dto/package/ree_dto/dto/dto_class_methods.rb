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

  def build(attrs = {}, **kwargs)
    dto_obj = new(attrs, **kwargs)
    set_attrs = attrs.keys + kwargs.keys
    fields_with_default = fields.select(&:has_default?)
    fields_to_set = fields_with_default.reject{ set_attrs.include?(_1.name) }

    fields_to_set.each do |field|
      dto_obj.set_attr(field.name, field.default)      
    end

    dto_obj
  end

  private

  def set_fields(v)
    @fields = v
  end

  def set_collections(v)
    @collections = v
  end
end