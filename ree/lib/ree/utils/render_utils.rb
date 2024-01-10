# frozen_string_literal: true

require 'erb'

class Ree::RenderUtils
  def self.render(template, locals)
    new(locals).render(template)
  end

  def initialize(locals = {})
    @render_binding = binding
    @locals         = locals
  end

  def render(template)
    @locals.each { |variable, value| @render_binding.local_variable_set(variable, value) }

    ERB.new(template).result(@render_binding)
  end
end
