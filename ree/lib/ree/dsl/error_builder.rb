# frozen_string_literal  = true

class Ree::ErrorBuilder
  def initialize(packages_facade)
    @packages_facade = packages_facade
  end

  def build(object, code, &proc)
    result = Ree::ErrorDsl.new.execute(object.klass, &proc)

    if result.is_a?(Ree::DomainError)
      object.klass.send(:remove_const, result.name) rescue nil
      result = Ree::ErrorDsl.new.execute(object.klass, &proc)
    end

    if !result.is_a?(Ree::ErrorDsl::ClassConstant)
      raise Ree::Error.new("invalid def_error usage", :invalid_dsl_usage)
    end

    object.klass.send(:remove_const, result.name) rescue nil

    object.klass.class_eval <<-ruby_eval, __FILE__, __LINE__ + 1
      class #{result.name} < Ree::DomainError
        attr_reader :code, :extra_code, :error_code, :package_name, :object_name

        def initialize(msg = nil, extra_code = nil)
          @code = #{code.inspect}
          @extra_code = extra_code
          @error_code = :#{Ree::StringUtils.underscore(result.name)}
          @package_name = :#{object.package_name}
          @object_name = :#{object.name}
          super(msg || #{result.message.inspect})
        end
      end
    ruby_eval

    result.name
  end
end