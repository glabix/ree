# frozen_string_literal: true

require_relative "action"

class ReeActions::ActionBuilder
  Redirect = Struct.new(:path, :code)

  def initialize
    @action = ReeActions::Action.new
    @action.respond_to = :json
  end

  contract Symbol => Symbol
  def warden_scope(scope)
    @action.warden_scope = scope
  end

  contract Symbol => Symbol
  def respond_to(v)
    @action.respond_to = v
  end

  contract None => ReeActions::Action
  def get_action
    @action
  end

  contract Block => nil
  def before(&proc)
    @action.before = proc
    nil
  end

  contract String => String
  def summary(str)
    @action.summary = str
  end

  contract Symbol, Symbol => nil
  def serializer(name, from:)
    object = Ree.container.packages_facade.get_object(from, name)
    @action.serializer = object
    nil
  end

  contract SplatOf[String] => nil
  def sections(*names)
    @action.sections = names
    nil
  end

  contract Symbol, Symbol => nil
  def action(name, from:)
    object = Ree.container.packages_facade.get_object(from, name)
    @action.action = object
    nil
  end

  contract String, Kwargs[code: Integer] => nil
  def redirect(path, code: 301)
    raise ArgumentError if ![301, 302, 303, 307, 308].include?(code)
    @action.redirect = Redirect.new(path, code)
    nil
  end
end