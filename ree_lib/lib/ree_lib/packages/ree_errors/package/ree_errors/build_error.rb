class ReeErrors::BuildError
  include Ree::FnDSL

  fn :build_error do
    link 'ree_errors/error', -> { Error }
  end

  contract Any, Symbol, Symbol, Nilor[String], Nilor[String] => SubclassOf[Error]
  def call(caller, type, code, locale, default_msg)
    klass = Class.new(Error)

    klass.instance_exec do
      @caller = caller
      @type = type
      @code = code
      @locale = locale
      @default_msg = default_msg
    end

    klass
  end
end