require 'net/https'
require "open-uri"

class Playlist
  include ERB::Util
  attr_accessor :title, :description, :author, :link, :image, :pub_date, :language, :copyright, :items, :id

  def initialize id
    @id = id
    @pages = []
    @items = []
    @cache = ActiveSupport::Cache::RedisStore.new
  end

  def to_podcast
    unless output = @cache.read(@id)
      download_info
      download_pages
      pages_to_items!
      output = "<?xml version='1.0' encoding='utf-8'?>
       <rss version='2.0' xmlns:itunes='http://www.itunes.com/DTDs/Podcast-1.0.dtd' xmlns:media='http://search.yahoo.com/mrss/'>
        <channel>
          <title>#{h(@title)}</title>
          <description>#{h(@description)}</description>
          <itunes:author>#{@author}</itunes:author>
          <link>#{@link}</link>
          <itunes:image href='#{@image}'></itunes:image>
          <pubDate>#{@pub_date}</pubDate>
          <language>#{@language}</language>
          <copyright>#{@copyright}</copyright>

          #{items_to_s}

        </channel>
      </rss>"
      @cache.write(@id, output, expire_in: 30.minutes)
      output
    else
      output
    end
  end

  def download_pages    
    @pages << download_page
    loop do
      if next_page_token = @pages.last.try(:[], "nextPageToken")
        @pages << download_page(next_page_token)
      else
        break
      end
    end
  end

  def download_page next_page_token=nil
    uri = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&maxResults=50&playlistId=#{@id}&key=#{Rails.application.secrets.youtube_api_key}"
    uri += "&pageToken=#{next_page_token}" if next_page_token
    JSON.parse URI.parse(uri).read
  end

  def pages_to_items!
    @pages.count.times do
      page = @pages.pop
      page["items"].each do |item|
        new_item = Item.new(item["contentDetails"]["videoId"])
        new_item.download_info
        @items << new_item
      end
    end
  end

  def download_info
    uri = "https://www.googleapis.com/youtube/v3/playlists?part=snippet&id=#{@id}&key=#{Rails.application.secrets.youtube_api_key}"
    if response = (JSON.parse URI.parse(uri).read)
      @title = response["items"][0]["snippet"]["title"] rescue nil
      @description = response["items"][0]["snippet"]["description"] rescue nil
      @author = response["items"][0]["snippet"]["channelTitle"] rescue nil
      @link = "https://youtube.com/user/" + response["items"][0]["snippet"]["channelTitle"] rescue nil
      @image = response["items"][0]["snippet"]["thumbnails"]["default"]["url"] rescue nil
      @pub_date = response["items"][0]["snippet"]["publishedAt"] rescue nil
    else
      nil
    end
  end

  def items_to_s
    output = ""
    @items.reverse!
    @items.each do |item|
      output += item.to_s
    end
    output
  end

end