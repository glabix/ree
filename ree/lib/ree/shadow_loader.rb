module Ree
  module ShadowConstMissing
    # ruby internal method
    def self.append_features(base)
      base.class_eval do
        # Emulate #exclude via an ivar
        return if defined?(@_const_missing) && @_const_missing
        @_const_missing = instance_method(:const_missing)
        remove_method(:const_missing)

        @@_ree_shadow_in_const_missing ||= false
        @@_ree_shadow_semaphore ||= Mutex.new
      end
      super
    end

    # return original const_missing
    def self.exclude_from(base)
      base.class_eval do
        if @_const_missing
          define_method :const_missing, @_const_missing
          @_const_missing = nil
        end
      end
    end

    def const_missing(const_name)
      @@_ree_shadow_semaphore.synchronize{
        raise_error(const_name) if @@_ree_shadow_in_const_missing

        load_package_object(self.to_s, const_name.to_s)
      }

      raise_error(const_name) unless self.const_defined?(const_name)

      return self.const_get(const_name)
    end

    private

    def load_package_object(package_name, const_name)
      @@_ree_shadow_in_const_missing = true

      package_name = underscore(package_name)
      file_name = underscore(const_name)

      facade = Ree.container.packages_facade
      facade.load_package_object(package_name.to_sym, file_name.to_sym)
    ensure
      @@_ree_shadow_in_const_missing = false
    end

    def raise_error(const_name)
      raise NameError.new("class not found #{const_name.to_s}", const_name)
    end

    def underscore(camel_cased_word)
      return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
      word = camel_cased_word.to_s.gsub("::".freeze, "/".freeze)
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'.freeze)
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2'.freeze)
      word.tr!("-".freeze, "_".freeze)
      word.downcase!
      word
    end
  end

  class ShadowLoader
    def self.enable
      Module.class_eval { include Ree::ShadowConstMissing }
    end

    def self.disable
      Ree::ShadowConstMissing.exclude_from(Module)
    end
  end
end