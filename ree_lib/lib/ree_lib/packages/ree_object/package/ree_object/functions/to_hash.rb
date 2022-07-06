# frozen_string_literal: true

class ReeObject::ToHash
  include Ree::FnDSL

  fn :to_hash do
    def_error { MissingIncludeKeyErr }
    def_error { RecursiveObjectErr }
  end

  DEFAULTS = {
    output_keys: :symbol,
    missing: :skip
  }.freeze
  
  BASIC_TYPES = [Date, Time, Numeric, String, FalseClass, TrueClass, NilClass, Symbol]

  contract(
    Any,
    Ksplat[
      include?: ArrayOf[Or[Symbol, Hash]],
      exclude?: ArrayOf[Or[Symbol, Hash]],
      output_keys?: Or[:symbol, :string],
      missing?: Or[:skip, :nil, :raise]
    ] => Or[Hash, ArrayOf[Any], *BASIC_TYPES]
  ).throws(ArgumentError, MissingIncludeKeyErr, RecursiveObjectErr)
  def call(obj, **opts)
    recursively_convert(obj, prepare_options(opts), {}, {})
  end

  private

  def recursively_convert(obj, opts, acc, cache)
    ancestors = obj.class.ancestors
    
    if ancestors.intersection(BASIC_TYPES).size > 0
      obj
    elsif obj.is_a?(Array)
      convert_array(obj, opts, acc, cache)
    elsif obj.is_a?(Hash)
      convert_hash(obj, opts, acc, cache)
    elsif obj.respond_to?(:to_h)
      convert_hash(obj.to_h, opts, acc, cache)
    else
      convert_object(obj, opts, acc, cache)
    end
  end

  def convert_array(obj, opts, acc, cache)
    obj.map { |el| recursively_convert(el, opts, {}, cache) }
  end

  def convert_hash(obj, opts, acc, cache)
    if opts[:include]
      opts[:include].each do |k|
        key_val, include_keys = get_include_keys(k)
        key = opts[:output_keys] == :symbol ? key_val.to_sym : key_val.to_s
        value = obj[key_val]

        if !obj.has_key?(key_val)
          next if opts[:missing] == :skip
          check_missing_key_value(k, opts)
        end

        acc[key] = recursively_convert(value, opts.merge(include: include_keys), {}, cache)
      end
    else
      obj.each do |k, v|
        sym_key = k.to_sym
        exclude_keys = if opts[:exclude]
          # if we got just key, not hash
          next if opts[:exclude].include?(sym_key)
          
          exclude_hash = opts[:exclude].find { |_k| _k.is_a?(Hash) && _k.keys.include?(sym_key) }

          if exclude_hash
            exclude_hash[sym_key]
          end
        end

        key = opts[:output_keys] == :symbol ? sym_key : k.to_s
        value = v

        acc[key] = recursively_convert(
          value, exclude_keys ? opts.merge(exclude: exclude_keys) : opts, {}, cache
        )
      end
    end

    acc
  end

  def convert_object(obj, opts, acc, cache)
    return obj if obj.is_a?(Class) || obj.is_a?(Module)

    raise RecursiveObjectErr, "Recursive object found: #{obj}" if cache.key?(obj.object_id)
    cache[obj.object_id] = acc
    
    if opts[:include]
      opts[:include].each do |k|
        key_val, include_keys = get_include_keys(k)
        key = opts[:output_keys] == :symbol ? key_val.to_s.delete("@").to_sym : key_val.to_s.delete("@")
        instance_var_sym = ['@', key.to_s].join.to_sym
        value = obj.instance_variable_get(instance_var_sym)

        if !obj.instance_variable_defined?(instance_var_sym)
          next if opts[:missing] == :skip
          check_missing_key_value(instance_var_sym, opts)
        end
        
        acc[key] = recursively_convert(value, opts.merge(include: include_keys), {}, cache)
      end
    else
      obj.instance_variables.each do |var|
        key_name = var.to_s.delete("@")
        key_sym = key_name.to_sym
        exclude_keys = if opts[:exclude]
          # if we got just key, not hash
          next if opts[:exclude].include?(key_sym)
          
          exclude_hash = opts[:exclude].find { |k| k.is_a?(Hash) && k.keys.include?(key_sym) }

          if exclude_hash
            exclude_hash[key_sym]
          end
        end

        key = opts[:output_keys] == :symbol ? key_sym : key_name
        value = obj.instance_variable_get(var)
  
        if !obj.instance_variable_defined?(var)
          next if opts[:missing] == :skip
          check_missing_key_value(var, opts)
        end
  
        acc[key] = recursively_convert(value, exclude_keys ? opts.merge(exclude: exclude_keys) : opts, {}, cache)
      end
    end

    acc
  end

  def check_missing_key_value(key, opts)
    return if !opts[:missing]
    raise MissingIncludeKeyErr, "Missing key `#{key}`" if opts[:missing] == :raise
  end

  def split_hash(arr)
    arr.map do |v|
      if v.is_a?(Symbol)
        v
      elsif v.is_a?(Hash)
        v.map { |k,v| { k => v } }
      end
    end.flatten
  end

  def prepare_options(opts)
    opts_with_defaults = DEFAULTS.dup.merge(opts)

    if opts_with_defaults[:include] && opts_with_defaults[:exclude]
      top_keys = ->(arr) { arr.map { |e| e.is_a?(Hash) ? (e.keys) : e }.flatten }
      intersection = top_keys.call(opts_with_defaults[:include]).intersection(top_keys.call(opts_with_defaults[:exclude]))

      if intersection.length > 0
        raise ArgumentError, "Exclude and include have same values: #{intersection}"
      end
    end

    if opts_with_defaults[:include]
      opts_with_defaults[:include] = split_hash(opts_with_defaults[:include])
    end

    if opts_with_defaults[:exclude]
      opts_with_defaults[:exclude] = split_hash(opts_with_defaults[:exclude])
    end

    opts_with_defaults
  end

  def get_include_keys(key_name)
    if key_name.is_a?(Hash)
      key_val = key_name.keys.first
      include_keys = key_name.length > 1 ? [*key_name[key_val], key_name.except(key_val)] : key_name[key_val]
    else
      key_val = key_name
      include_keys = nil
    end

    [key_val, include_keys]
  end
end