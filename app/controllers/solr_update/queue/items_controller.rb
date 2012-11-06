class SolrUpdate::Queue::ItemsController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def index
    render :json => SolrUpdate::Queue::Item.all
  end

end
