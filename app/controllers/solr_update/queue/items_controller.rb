class SolrUpdate::Queue::ItemsController < ApplicationController

  respond_to :json
  respond_to :html, :only => [:index]

  before_filter :authenticate_user!

  before_filter :authorize_admin_user!

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'created_at asc', Public::SolrUpdate::Queue::Item, :public_search)
      end

      format.html
    end
  end

  def run
    item = SolrUpdate::Queue::Item.find(params[:id])
    SolrUpdate::Queue.process_item(item)
    head :ok
  end

  def destroy
    item = SolrUpdate::Queue::Item.find(params[:id])
    item.destroy
    head :ok
  end

end
