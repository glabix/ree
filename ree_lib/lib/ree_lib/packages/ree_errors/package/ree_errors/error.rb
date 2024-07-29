module ReeErrors
  class Error < StandardError
    include Ree::LinkDSL

    link :t, from: :ree_i18n
    link :check_locale_exists, from: :ree_i18n
    link :underscore, from: :ree_string

    def initialize(msg = nil)
      if !msg && !locale && !default_msg
        raise ArgumentError, "message, locale or default message should be specified"
      end

      message = if msg
        msg
      elsif default_msg
        default_msg
      else
        path = (locale || code).to_s
        has_path = path.include?(".")

        if has_path
          pre_path = [caller_module, caller_class].compact.map { underscore(_)}.join(".")

          if check_locale_exists(path)
            t(path, default_by_locale: :en)
          else
            t("#{pre_path}.#{path}", default_by_locale: :en)
          end
        else
          if caller_module
            mod = underscore(caller_module)
            klass = underscore(caller_class)

            if check_locale_exists(loc = "#{mod}.errors.#{klass}.#{path}")
              t(loc, default_by_locale: :en)
            else check_locale_exists(loc = "#{mod}.errors.#{path}")
              t(loc, default_by_locale: :en)
            end
          else
          end
        end
      end

      super(message)
    end

    def type
      t = self.class.instance_variable_get(:@type)

      if !t
        raise ArgumentError.new(
          "type was not specified for domain error => #{self.inspect}"
        )
      end

      t
    end

    def default_msg
      self.class.instance_variable_get(:@default_msg)
    end

    def locale
      self.class.instance_variable_get(:@locale)
    end

    def caller
      self.class.instance_variable_get(:@caller)
    end

    def caller_module
      @caller_module ||= begin
        if !caller
          nil
        else
          c = caller

          if c.is_a?(Class)
            extract_module_name(c.to_s)
          else
            extract_module_name(c.class.to_s)
          end
        end
      end
    end

    def caller_class
      @caller_class ||= begin
        if !caller
          nil
        else
          c = caller

          if c.is_a?(Class)
            extract_class_name(c.to_s)
          else
            extract_class_name(c.class.to_s)
          end
        end
      end
    end

    def code
      c = self.class.instance_variable_get(:@code)

      if !c
        raise ArgumentError.new(
          "code not specified for error => #{self.inspect}"
        )
      end

      c
    end

    private

    def extract_module_name(klass_str)
      class_name = klass_str.split("::").first
      return nil if class_name == klass_str
      return class_name
    end

    def extract_class_name(klass_str)
      klass_str.split("::").last
    end
  end
end