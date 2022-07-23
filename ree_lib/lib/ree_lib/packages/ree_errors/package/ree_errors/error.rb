module ReeErrors
  class Error < StandardError
    include Ree::LinkDSL

    link :t, from: :ree_i18n

    def initialize(msg = nil)
      if !locale && !msg
        raise ArgumentError, "message or locale should be specified"
      end

      super(
        locale ? t(locale, default_by_locale: :en) : msg
      )
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

    def locale
      self.class.instance_variable_get(:@locale)
    end

    def code
      c = self.class.instance_variable_get(:@code)

      if !c
        raise ArgumentError.new(
          "code was not specified for domain error => #{self.inspect}"
        )
      end

      c
    end
  end
end