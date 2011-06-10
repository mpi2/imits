class CentresController < ApplicationController
  respond_to :xml, :json

  def show
    @centre = Centre.find(params[:id])
    respond_with @centre
  end

  def index
    search_params = params.dup.delete_if {|k| ['controller', 'action', 'format', 'page'].include? k }
    @centres = Centre.search(search_params).all
    respond_with @centres
  end

end
