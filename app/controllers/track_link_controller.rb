class TrackLinkController < ApplicationController

  respond_to :json
  respond_to :html, :except => [:show]

  before_filter :authenticate_user!

  def link_to
    forward_address = params[:forward_address]
    type = params[:type].try(:downcase)

    request_date = Time.now
    if ! forward_address.blank?
      track_link = TrackLink.new({:ip_address => request.ip, :http_refer => request.referer, :link_clicked => forward_address, :link_type => type, :year => request_date.year, :month => request_date.month, :day =>request_date.day, :created_at => Time.now})
      puts request.ip
      puts request.referer
      puts request.server_name
      puts Time.now

      track_link.save
    end

    redirect_to "#{forward_address}"
  end

end