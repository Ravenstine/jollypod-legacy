class ShortlinksController < ApplicationController
  def follow
    if link = Playlist.link_from_guid(params[:guid])
      redirect_to link
    else
      redirect_to root_path
    end
  end
end