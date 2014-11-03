class Item
  include ERB::Util

  attr_accessor :title, :description, :author, :pub_date, :link

  def initialize
    @pub_date ||= DateTime.now
  end

  def to_s
    "<item>
      <title>#{h(@title)}</title>
      <description>#{h(@description)}</description>
      <itunes:author>#{h(@author)}</itunes:author>
      <pubDate>#{@pub_date}</pubDate>
      <enclosure url='#{link}' type='audio/mpeg' /> 
    </item>"
  end
end