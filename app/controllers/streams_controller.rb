class StreamsController < ApplicationController
  include ActionController::Live
  require 'open3'
  require 'timeout'

  def stream
    video_url = ViddlRb.get_urls("https://www.youtube.com/watch?v=#{params[:id]}").first
    curl_cmd = "curl '#{video_url}' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Connection: keep-alive' -H 'Accept-Encoding: gzip,deflate,sdch' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36' --compressed"
    cmd = "exec #{curl_cmd} | ffmpeg -y -i pipe:0 -ac 1 -ab 16000 -ar 22050 -f mp3 -"
    response.headers['Content-Type'] = 'audio/mp3'
    response.headers['Content-Transfer-Encoding'] = 'binary'
    response.headers['Content-Disposition'] = 'attachment; filename="test.mp3"'
    response.sending_file = false
    
    pid = nil
    stdin, stdout, wait_thr = Open3.popen2(cmd)
    pid = wait_thr.pid
    
    stdout.each do |blob|
      Timeout::timeout(30) do
        response.stream.write blob
      end
    end
  rescue IOError
  ensure
    puts ""
    puts "Stream closed."
    `kill -9 #{pid}`
    stdin.close
    stdout.close
    response.stream.close
  end

  def podcast
    render xml: Playlist.new(params[:id]).to_podcast, layout: false
  end 

end
