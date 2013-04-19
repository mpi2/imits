class CentresController < ApplicationController

  respond_to :json
  respond_to :html, :except => [:show]

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def show
    find_centre
    respond_with @centre
  end

  def create
    @centre = Centre.new(params[:centre])

    respond_to do |format|
      if @centre.save
        format.html { redirect_to :centres, :notice => "Centre was created successfully." }
        format.json { respond_with @centre }
      else
        format.html { redirect_to :centres, :alert => 'Could not create centre (name must be present and unique)' }
        format.json { render(:json => {'error' => 'Could not create centre (name must be present and unique)'}, :status => 422) }
      end
    end
  end

  def update
    find_centre

    respond_to do |format|
      if @centre.update_attributes(params[:centre])
        format.html { redirect_to :centres, :notice => "Centre was updated successfully." }
        format.json { respond_with @centre }
      else
        format.html { redirect_to :centres, :alert => 'Could not update centre (name must be present and unique)' }
        format.json { render(:json => {'error' => 'Could not update centre (name must be present and unique)'}, :status => 422) }
      end
    end
  end

  def destroy
    find_centre

    respond_to do |format|
      if @centre.destroy
        format.html { redirect_to :centres, :notice => "The centre '#{@centre.name}' has been deleted." }
        format.json { render :nothing => true, :status => 200 }
      else
        format.html { redirect_to :centres, :notice => "Could not delete centre (has children)" }
        format.json { render(:json => {'error' => 'Could not delete centre (has children)'}, :status => 422) }
      end
    end
  end

  private

  def find_centre
    @centre = Centre.find(params[:id])
  end

  def data_for_serialized(format)
    super(format, 'id', Centre, :search, false)
  end

end