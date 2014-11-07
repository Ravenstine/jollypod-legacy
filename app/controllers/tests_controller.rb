class TestsController < ApplicationController
  include ActionController::Live
  require 'open3'
  require 'rss'

  def show
    video_url = ViddlRb.get_urls("https://www.youtube.com/watch?v=#{params[:id]}").first
    curl_cmd = "curl '#{video_url}' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Connection: keep-alive' -H 'Accept-Encoding: gzip,deflate,sdch' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36' --compressed"
    cmd = "exec #{curl_cmd} | ffmpeg -y -i pipe:0 -ac 1 -ab 16000 -ar 22050 -f mp3 -"
    response.headers['Content-Type'] = 'audio/mp3'
    response.headers['Content-Transfer-Encoding'] = 'binary'
    response.headers['Content-Disposition'] = 'attachment; filename="test.mp3"'
    response.sending_file = false
    
    pid = nil
    Open3.popen2(cmd) do |stdin, stdout, wait_thr|
      pid = wait_thr.pid
      stdout.each do |blob|
        response.stream.write blob
      end
    end
  rescue IOError
    puts "Stream closed."
  ensure
    `kill -9 #{pid}`
    response.stream.close
  end

  def playlist
    rss = RSS::Parser.parse Net::HTTP.get("gdata.youtube.com", "/feeds/api/playlists/#{params[:id]}")
    podcast = Podcast.new 
    podcast.title = rss.title.content
    podcast.description = rss.subtitle.content
    podcast.author = rss.author.name.content
    podcast.link = rss.link.href
    podcast.image = rss.logo.content
    podcast.pub_date = rss.updated.content
    podcast.copyright = rss.rights.try(:content)

    rss.items.each do |element|
      item = Item.new
      item.title = element.title.content
      item.description = element.content.content
      item.author = element.author.name.content
      item.pub_date = element.published.content
      video_id = element.link.href.match(/v=([a-zA-Z0-9_\-]*)/)[1]
      item.link = "http://104.8.69.205:3000/mp3/#{video_id}"
      podcast << item
    end
    File.open("dump.xml", 'w') { |file| file.write(podcast.to_s) }
    render xml: podcast.to_s, layout: false
  end 

end
