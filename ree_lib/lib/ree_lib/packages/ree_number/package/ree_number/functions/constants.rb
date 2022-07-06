# frozen_string_literal: true

class ReeNumber::Constants
  DECIMAL_UNITS = { 
    0 => :unit,
    1 => :one, 
    2 => :hundred, 
    3 => :thousand, 
    6 => :million, 
    9 => :billion, 
    12 => :trillion, 
    15 => :quadrillion,
    -1 => :deci, 
    -2 => :centi, 
    -3 => :mili, 
    -6 => :micro, 
    -9 => :nano, 
    -12 => :pico, 
    -15 => :femto 
  }

  INVERTED_DECIMAL_UNITS = DECIMAL_UNITS.invert

  STORAGE_UNITS = [:byte, :kb, :mb, :gb, :tb, :pb, :eb]
end