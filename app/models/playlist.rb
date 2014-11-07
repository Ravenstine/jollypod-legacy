require 'net/https'

class Playlist

  attr_accessor :title, :description, :author, :link, :image, :pub_date, :language, :copyright, :items

  def initialize id
    @id = id
    @pages = []
  end

  def to_podcast
    download_pages
  end

  def download_pages
    require "open-uri"
    
    @pages << download_page

    loop do
      if next_page_token = @pages.last.try(:[], "nextPageToken")
        @pages << download_page(next_page_token)
      else
        break
      end
    end

    # binding.pry
  end


  


  def download_page next_page_token=nil
    uri = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&maxResults=50&playlistId=#{@id}&key=#{Rails.application.secrets.youtube_api_key}"
    uri += "&pageToken=#{next_page_token}" if next_page_token
    JSON.parse URI.parse(uri).read
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

end