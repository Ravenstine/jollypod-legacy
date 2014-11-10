class HomeController < ApplicationController
  def index
  end

  def link
    if @url = Playlist.url_to_shortlink(params[:url])
      @qr = RQRCode::QRCode.new @url, size: 4, level: :l 
      render "link"
    else
      flash[:alert] = "There was a problem with the URL you entered.  Try again with a different one."
      redirect_to root_path
    end
  end

  def faq
  end

end
