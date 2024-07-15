# frozen_string_literal: true

class ReeMapper::Field
  attr_reader :type, :name, :from, :doc, :optional, :null, :roles, :default,
              :name_as_str, :name_as_instance_var_name, :from_as_str,
              :fields_filter, :location

  NO_DEFAULT = Object.new.freeze

  contract(
    Any,
    Nilor[Symbol],
    Kwargs[
      from:     Nilor[Symbol],
      doc:      Nilor[String],
      optional: Bool,
      null:     Bool,
      role:     Nilor[ArrayOf[Symbol], Symbol],
      default:  Any,
      only:     Nilor[ReeMapper::FilterFieldsContract],
      except:   Nilor[ReeMapper::FilterFieldsContract],
      location: Nilor[String],
    ] => Any
  ).throws(ArgumentError)
  def initialize(type, name = nil, from: nil, doc: nil, optional: false, null: false, role: nil, default: NO_DEFAULT,
                 only: nil, except: nil, location: nil)
    @type     = type
    @name     = name
    @from     = from || name
    @doc      = doc
    @optional = optional
    @null     = null
    @roles    = Array(role)
    @default  = default

    @fields_filter = ReeMapper::FieldsFilter.build(only, except)

    @name_as_str               = @name.to_s
    @name_as_instance_var_name = :"@#{@name}"
    @from_as_str               = @from.to_s

    @location = location
    if @location
      @location = @location
        .sub(Ree.root_dir, ".")
        .sub(/:in.+/, "")
    end

    raise ArgumentError, 'required fields do not support defaults' if has_default? && !optional
  end

  contract None => Bool
  def has_default?
    default != NO_DEFAULT
  end

  contract Nilor[Symbol, ArrayOf[Symbol]] => Bool
  def has_role?(role)
    return true  if roles.empty?
    return false if role.nil?

    if role.is_a?(Array)
      role.any? { roles.include?(_1) }
    else
      roles.include?(role)
    end
  end
end
