# frozen_string_literal  = true

class Ree::ErrorDsl
  def execute(klass, &proc)
    self.class.instance_exec(&proc)
  rescue NameError => e
    proc
      .binding
      .eval("#{e.name} = Ree::ErrorDsl::ClassConstant.new('#{e.name}')")

    retry
  end

  class ClassConstant
    attr_reader :name, :message

    def initialize(name)
      @name = name
      @message = nil
    end

    def [](msg)
      @message = msg
      self
    end
  end
end