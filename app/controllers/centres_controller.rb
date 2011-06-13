class CentresController < ApplicationController
  respond_to :xml, :json

  def show
    @centre = Centre.find(params[:id])
    respond_with @centre
  end

  def index
    @centres = Centre.search(cleaned_params).all
    respond_with @centres
  end

end
