class Ree::TemplateRenderer
  TEMPLATE_VARIABLE = /<%=\s*([\w\d-]+)\s*%>/i

  class << self
    def handle(template, locals = {})
      Ree::TemplateRenderer.new(template, locals).handle
    end

    def get_undefined_variables(template, locals = {})
      Ree::TemplateRenderer.new(template, locals).get_undefined_variables
    end
  end

  def initialize(template, locals)
    @template = template
    @locals   = locals
    @undefined_variables = []
  end

  def handle
    raise Ree::Error.new("Template variable not defined: #{get_undefined_variables.map(&:to_s).join(';')}") if get_undefined_variables.any?

    Ree::RenderUtils.render(@template, @locals)
  end

  def get_undefined_variables
    Ree::RenderUtils.render(@template, @locals)

    @undefined_variables
  rescue NameError => e
    raise NoMethodError, "Undefined method for template. Please, add :#{e.name} method to .ree/helpers/render_helper.rb file!" if @undefined_variables.include?(e.name)

    @locals[e.name] = e.name.to_s
    @undefined_variables.push(e.name)

    retry
  end

  private

  def get_template_variables
    Ree::RenderUtils.render(@template, {})
  rescue NameError => e
    @locals

    get_template_variables(@template, fake_locals, undefined_variables)
  end

  def get_passed_variables
    @locals
      .keys
      .uniq
      .map(&:intern)
  end
end