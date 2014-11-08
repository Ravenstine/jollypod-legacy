class Item
  include ERB::Util

  attr_accessor :title, :description, :author, :pub_date, :link, :video_id, :image

  def initialize video_id=nil
    @video_id = video_id
    @pub_date ||= DateTime.now
  end

  def download_info
    uri = "https://www.googleapis.com/youtube/v3/videos?part=snippet&id=#{@video_id}&key=#{Rails.application.secrets.youtube_api_key}"
    if response = (JSON.parse URI.parse(uri).read)
      @title = response["items"][0]["snippet"]["title"] rescue nil
      @description = response["items"][0]["snippet"]["description"] rescue nil
      @author = response["items"][0]["snippet"]["channelTitle"] rescue nil
      @link = @video_id ? "http://youcast.com/#{@video_id}" : nil
      @image = response["items"][0]["snippet"]["thumbnails"]["default"]["url"] rescue nil
      @pub_date = response["items"][0]["snippet"]["publishedAt"] rescue nil
    else
      nil
    end
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