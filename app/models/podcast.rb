class Podcast
  include ERB::Util

  attr_accessor :title, :description, :author, :link, :image, :pub_date, :language, :copyright, :items

  def initialize
    @language ||= "en-us"
    @pub_date ||= DateTime.now
    @items ||= []
  end

  def to_s
    "<?xml version='1.0' encoding='utf-8'?>
     <rss version='2.0' xmlns:itunes='http://www.itunes.com/DTDs/Podcast-1.0.dtd' xmlns:media='http://search.yahoo.com/mrss/'>
      <channel>
        <title>#{h(@title)}</title>
        <description>#{h(@description)}</description>
        <itunes:author>#{h(@author)}</itunes:author>
        <link>#{@link}</link>
        <itunes:image href='#{@image}'></itunes:image>
        <pubDate>#{@pub_date}</pubDate>
        <language>#{@language}</language>
        <copyright>#{@copyright}</copyright>

        #{items_to_s}

      </channel>
    </rss>"
  end

  def items_to_s
    output = ""
    items.each do |item|
      output += item.to_s
    end
    output
  end

  def <<(item)
    raise "Invalid item" if item.class != Item
    @items << item
  end

end