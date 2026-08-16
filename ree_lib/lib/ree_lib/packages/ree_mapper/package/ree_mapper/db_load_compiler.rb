# frozen_string_literal: true

# Compiles a specialized :db_load for composite mappers when
# Ree.db_load_performance_mode? is on at mapper build time.
#
# The compiled method handles the hot call shape `db_load(hash)` with no
# role/filters as straight-line per-field code: values of primitive types
# skip casting behind a cheap type guard (see AbstractType#db_load_trusted_check),
# non-trusted types (custom, enums, pg wrappers, nested mappers) are cast as
# usual, and dto construction goes through a single attrs hash instead of
# build-then-copy. Every other call shape falls back to the untouched generic
# method, kept as __generic_db_load.
#
# Codegen targets the mapper's anonymous class (each Mapper.build creates
# one), never the instance: registered mappers are frozen.
class ReeMapper::DbLoadCompiler
  class << self
    def compile(mapper)
      return if mapper.type # leaf mappers keep their generic delegation

      strategy = mapper.find_strategy(:db_load)
      return unless strategy

      case (output = strategy.output)
      when ReeMapper::ReeDtoOutput
        builder  = "acc = {}"
        finisher = "DB_LOAD_DTO.build_from_attrs(acc)"
      when ReeMapper::HashOutput
        return unless strategy.dto == ::Hash # OpenStruct keeps the generic path
        builder  = "acc = {}"
        finisher = "acc"
      when ReeMapper::ObjectOutput
        builder  = "acc = DB_LOAD_DTO.allocate"
        finisher = "acc"
      else
        return # StructOutput and unknown outputs keep the generic path
      end

      klass = mapper.class
      return if klass.method_defined?(:__generic_db_load, false) # already compiled

      fields = mapper.fields.values

      set_const(klass, :DB_LOAD_FIELDS, fields.freeze)
      set_const(klass, :DB_LOAD_DTO, strategy.dto)
      set_const(
        klass,
        :DB_LOAD_NESTED_FILTERS,
        fields.map { _1.fields_filter ? [_1.fields_filter].freeze : nil }.freeze
      )

      body = fields.each_with_index.filter_map { |field, idx|
        # the generic loop skips role-scoped fields when role is nil; calls
        # with an actual role go through the generic fallback
        next unless field.roles.empty?
        field_code(field, idx, output, strategy.always_optional)
      }.join("\n")

      klass.send(:alias_method, :__generic_db_load, :db_load)

      klass.class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def db_load(obj, role: nil, only: nil, except: nil, fields_filters: nil)
          if role || only || except || fields_filters || !obj.is_a?(::Hash)
            return __generic_db_load(obj, role: role, only: only, except: except, fields_filters: fields_filters)
          end

          #{builder}
          #{body}
          #{finisher}
        end
      RUBY

      # keep the generated source inspectable for debugging
      klass.instance_variable_set(:@compiled_db_load_source, body)

      nil
    end

    private

    def field_code(field, idx, output, always_optional)
      cast_expr = "__dbl_cast(DB_LOAD_FIELDS[#{idx}], v, DB_LOAD_NESTED_FILTERS[#{idx}])"
      guard = field.type.db_load_trusted_check("v")

      value_expr = if guard == "true"
        # identity type (any): nil also passes through unchanged, as in the
        # generic loop where Any#db_load(nil) returns nil
        "v"
      elsif guard
        if field.null
          "v.nil? ? nil : (#{guard} ? v : #{cast_expr})"
        else
          "#{guard} ? v : #{cast_expr}"
        end
      else
        if field.null
          "v.nil? ? nil : #{cast_expr}"
        else
          cast_expr
        end
      end

      sym_key = field.from.inspect
      str_key = field.from_as_str.inspect

      missing_code = if field.optional || always_optional
        assign(field, output, "DB_LOAD_FIELDS[#{idx}].default") if field.has_default?
      else
        <<~RUBY.chomp
          raise ReeMapper::TypeError.new(
            "is missing (required field)", DB_LOAD_FIELDS[#{idx}].location, [#{str_key}]
          )
        RUBY
      end

      code = +<<~RUBY
        if obj.key?(#{sym_key})
          v = obj[#{sym_key}]
          #{assign(field, output, value_expr)}
        elsif obj.key?(#{str_key})
          v = obj[#{str_key}]
          #{assign(field, output, value_expr)}
      RUBY

      if missing_code
        code << "else\n  #{missing_code}\n"
      end

      code << "end\n"
    end

    def assign(field, output, value_expr)
      if output.is_a?(ReeMapper::ObjectOutput)
        "acc.instance_variable_set(#{field.name_as_instance_var_name.inspect}, #{value_expr})"
      else
        "acc[#{field.name.inspect}] = #{value_expr}"
      end
    end

    def set_const(klass, name, value)
      klass.send(:remove_const, name) if klass.const_defined?(name, false)
      klass.const_set(name, value)
    end
  end
end
