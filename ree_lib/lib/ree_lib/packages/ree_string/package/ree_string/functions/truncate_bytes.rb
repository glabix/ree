# frozen_string_literal: true

class ReeString::TruncateBytes
  include Ree::FnDSL

  fn :truncate_bytes

  DEFAULT_OMISSION = "…"

  doc(<<~DOC)
    Truncates +text+ to at most <tt>bytesize</tt> bytes in length without
    breaking string encoding by splitting multibyte characters or breaking
    grapheme clusters ("perceptual characters") by truncating at combining
    characters.
    
      >> "🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪".size
      => 20
      >> "🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪".bytesize
      => 80
      >> truncate_bytes("🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪", 20)
      => "🔪🔪🔪🔪…"
    
    The truncated text ends with the <tt>:omission</tt> string, defaulting
    to "…", for a total length not exceeding <tt>bytesize</tt>.
  DOC
  contract(
    String,
    Integer,
    Ksplat[
      omission?: String,
    ] => String
  ).throws(ArgumentError)
  def call(str, truncate_at, **opts)
    str = str.dup
    omission = opts[:omission] || DEFAULT_OMISSION

    case
    when str.bytesize <= truncate_at
      str
    when omission.bytesize > truncate_at
      raise ArgumentError, "Omission #{omission.inspect} is #{omission.bytesize}, larger than the truncation length of #{truncate_at} bytes"
    when omission.bytesize == truncate_at
      omission.dup
    else
      String.new.tap do |cut|
        cut_at = truncate_at - omission.bytesize

        str.each_grapheme_cluster do |grapheme|
          if cut.bytesize + grapheme.bytesize <= cut_at
            cut << grapheme
          else
            break
          end
        end

        cut << omission
      end
    end
  end
end