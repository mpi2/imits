class StrainsController < ApplicationController

  respond_to :json
  respond_to :html, :only => [:create, :index]

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def create
    @strain = Strain.new(params[:strain])

    respond_to do |format|
      if @strain.save
        format.html { redirect_to :strains, :notice => "Strain was created successfully." }
        format.json { respond_with @strain }
      else
        format.html { redirect_to :strains, :alert => "Could not create strain, #{@strain.errors.full_messages}." }
        format.json { render(:json => {'error' => "Could not create strain, #{@strain.errors.full_messages}."}, :status => 422) }
      end
    end
  end

  def update
    find_strain

    respond_to do |format|
      if @strain.update_attributes(params[:strain])
        format.json { respond_with @strain }
      else
        format.json { render(:json => {'error' => "Could not update centre, #{@strain.errors.full_messages}."}, :status => 422) }
      end
    end
  end

  def destroy
    find_strain

    respond_to do |format|
      if @strain.destroy
        format.json { render :nothing => true, :status => 200 }
      else
        format.json { render(:json => {'error' => 'Could not delete strain (has children)'}, :status => 422) }
      end
    end
  end

  private

  def find_strain
    @strain = Strain.find(params[:id])
  end

  def data_for_serialized(format)
    super(format, 'id', Strain, :search)
  end
end