# frozen_string_literal: true

require_relative "route"

class ReeRoutes::RouteBuilder
  Redirect = Struct.new(:path, :code)

  VISIBILITIES = [:public, :internal].freeze
  AUDIT_MODES = [true, false, :on_annotation].freeze

  def initialize
    @route = ReeRoutes::Route.new
    @route.respond_to = :json
  end

  contract SplatOf[Symbol] => ArrayOf[Symbol]
  def warden_scope(*scopes)
    @route.warden_scopes = scopes.flatten
  end

  contract Symbol => Symbol
  def respond_to(v)
    @route.respond_to = v
  end

  contract None => ReeRoutes::Route
  def get_route
    @route
  end

  contract Block => nil
  def before(&proc)
    @route.before = proc
    nil
  end

  contract Block => nil
  def override(&proc)
    @route.override = proc
    nil
  end

  contract String => String
  def summary(str)
    @route.summary = str
  end

  # Needed in exactly three cases: silencing a noisy internal route, turning
  # the trail on for a public route that reaches into someone else's data, and
  # `:on_annotation` for a route both the owner of the data and a staff member
  # can call — see Route#audit_on_annotation?.
  contract Or[Bool, Symbol] => Or[Bool, Symbol]
  def audit(value)
    if !AUDIT_MODES.include?(value)
      raise ArgumentError.new(
        "audit should be one of #{AUDIT_MODES.inspect}, got #{value.inspect}"
      )
    end

    @route.audit = value
  end

  contract Symbol => Symbol
  def visibility(value)
    if !VISIBILITIES.include?(value)
      raise ArgumentError.new(
        "visibility should be one of #{VISIBILITIES.inspect}, got #{value.inspect}"
      )
    end

    @route.visibility = value
  end

  contract Symbol, Symbol => nil
  def serializer(name, from:)
    object = Ree.container.packages_facade.get_object(from, name)
    @route.serializer = object
    nil
  end

  contract SplatOf[String] => nil
  def sections(*names)
    @route.sections = names
    nil
  end

  contract Symbol, Symbol => nil
  def action(name, from:)
    object = Ree.container.packages_facade.get_object(from, name)
    @route.action = object
    nil
  end

  contract String, Kwargs[code: Integer] => nil
  def redirect(path, code: 301)
    raise ArgumentError if ![301, 302, 303, 307, 308].include?(code)
    @route.redirect = Redirect.new(path, code)
    nil
  end
end
