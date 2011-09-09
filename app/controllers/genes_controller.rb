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
    params[:sorts] = 'marker_symbol' if(params[:sorts].blank?)
    params.delete(:per_page) if params[:per_page].blank? or params[:per_page].to_i == 0

    result = Gene.search(params_cleaned_for_search(params)).result
    retval = result.paginate(:page => params[:page], :per_page => params[:per_page] || 20)

    if format == :json and params[:extended_response].to_s == 'true'
      return json_format_extended_response(retval, result.count)
    else
      return retval
    end
  end

  def json_format_extended_response(data, total)
    data = [data] unless data.kind_of? Array
    data = data.as_json

    retval = {
      'genes' => data,
      'success' => true,
      'total' => total
    }
    return retval
  end

end
