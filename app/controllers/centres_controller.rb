class CentresController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def show
    find_centre
    respond_with @centre
  end

  def create
    @centre = Centre.new(params[:centre])
    
    if @centre.save
      respond_with @centre
    else
      render(:json => {'error' => 'Centre name must be present and unique.'}, :status => 422)
    end
  end

  def update
    find_centre

    if @centre.update_attributes(params[:centre])
      respond_with @centre
    else
      render(:json => {'error' => 'Centre name must be present and unique.'}, :status => 422)
    end
  end

  def destroy
    find_centre
    @centre.destroy
    render :nothing => true, :status => 200
  end

  private

  def find_centre
    @centre = Centre.find(params[:id])
  end

  def data_for_serialized(format)
    super(format, 'id', Centre, :search)
  end

end