class TargRep::Lims2SearchesController < TargRep::BaseController

  respond_to :json

  def get_crispr_group_data
    error = ""
    params_passed = true
    group_id = nil
    group_id = params[:group_id].to_i if params.has_key?(:group_id) && params[:group_id].to_i != 0

    ## check Params
    if group_id.blank? or (! group_id.is_a? Integer)
      error = "group_id required"
      params_passed = false
    end

    if params_passed
      crispr_group = TargRep::Lims2CrisprGroup.find_by_group_id(group_id)
      if !crispr_group.errors.blank?
        error = "No crispr group data found for group_id: #{params[:group_id]}"
      end
   end

    respond_to do |format|
      if error.blank?
        format.json { render :json => crispr_group.to_json}
      else
        format.json { render :json => error.to_json, status: 404}
      end
    end
  end
end

