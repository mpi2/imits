class GenesController < ApplicationController
  respond_to :json, :xml
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.xml  { render :xml => data_for_serialized(:xml) }
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  private

  def data_for_serialized(format)
    super(format, 'marker_symbol', Gene, :search)
  end

end
