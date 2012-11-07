class SolrUpdate::Queue::ItemsController < ApplicationController

  respond_to :json, :html

  before_filter :authenticate_user!

  before_filter :authorize_admin_user!

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'id asc', Public::SolrUpdate::Queue::Item, :public_search)
      end

      format.html
    end
  end

end
