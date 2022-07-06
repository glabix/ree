# frozen_string_literal: true

class ReeText::StripTags
  include Ree::FnDSL

  fn :strip_tags do
    link :is_blank, from: :ree_object
    link 'ree_text/scrubbers/text_only_scrubber', -> { TextOnlyScrubber }
  end

  doc(<<~DOC)
    Strips all HTML tags from +html+, including comments and special characters.
    
      strip_tags("Strip <i>these</i> tags!")
      # => Strip these tags!
    
      strip_tags("<b>Bold</b> no more!  <a href='more.html'>See more here</a>...")
      # => Bold no more!  See more here...
    
      strip_tags("<div id='top-bar'>Welcome to my website!</div>")
      # => Welcome to my website!
    
      strip_tags("> A quote from Smith & Wesson")
      # => &gt; A quote from Smith &amp; Wesson
  DOC
  
  contract(String => String)
  def call(html)
    return html if is_blank(html)

    loofah_fragment = Loofah.fragment(html)
    loofah_fragment.scrub!(TextOnlyScrubber.new)
    properly_encode(loofah_fragment, encoding: 'UTF-8')
  end

  private

  def properly_encode(fragment, options)
    fragment.xml? ? fragment.to_xml(options) : fragment.to_html(options)
  end
end