class ReeErrors::BuildError
  include Ree::FnDSL

  fn :build_error do
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Symbol, Nilor[String] => SubclassOf[Error]
  def call(type, code, locale)
    klass = Class.new(Error)

    klass.instance_exec do
      @type = type
      @code = code
      @locale = locale
    end

    klass
  end
end