require_relative "./field_meta"
require_relative "./collection_meta"

module ReeDto::DtoClassMethods
  include Ree::Contracts::Core
  include Ree::Contracts::ArgContracts

  contract None => ArrayOf[ReeDto::FieldMeta]
  def fields
    @fields ||= []
  end

  contract None => ArrayOf[ReeDto::FieldMeta]
  def fields_with_default
    @fields_with_default ||= []
  end

  contract None => ArrayOf[ReeDto::CollectionMeta]
  def collections
    @collections ||= []
  end

  def build(attrs = nil, **kwargs)
    dto_obj = new(attrs || kwargs)
    set_attrs = attrs ? attrs.keys : kwargs.keys
    fields_to_set = fields_with_default.reject{ set_attrs.include?(_1.name) }

    fields_to_set.each do |field|
      dto_obj.set_attr(field.name, field.default)      
    end

    dto_obj
  end

  # Fast-path constructor used by compiled db_load: takes ownership of attrs
  # (it becomes @_attrs without copying), so callers must not reuse the hash.
  # Reads @fields_with_default directly: the contract-wrapped reader would
  # revalidate the array on every row.
  def build_from_attrs(attrs)
    (@fields_with_default || []).each do |field|
      attrs[field.name] = field.default unless attrs.key?(field.name)
    end

    dto_obj = allocate
    dto_obj.instance_variable_set(:@_attrs, attrs)
    dto_obj
  end

  private

  def set_fields(v)
    @fields = v
  end

  def set_fields_with_default(v)
    @fields_with_default = v
  end

  def set_collections(v)
    @collections = v
  end
end