class GeneListController < ApplicationController
#  respond_to :html, :only => [:gene_management]
#  respond_to :json, :except => [:genes_of_interest, :assigned_genes, :register_interest_in_gene, :assign_gene, :unassign_gene, :withdraw_gene. :gene_management]
  before_filter :authenticate_user!

# views
#  def gene_management

#  end

# data selections
#  def genes_of_interest
#    marker_symbols = params[:marker_symbols].lines.map(&:strip).select{|i|!i.blank?}.uniq if params.has_key?(:marker_symbols)
#    inverse_search = params[:inverse_search] == 'true' ? true : false
#    ignore_warnings = params[:ignore_warnings] == 'true' ? true :false
#    error = ""
#    gene_found_and_missing = validate_marker_symbols(marker_symbols)
#    centre = current_user.production_centre
#    centre = Centre.where("name = #{params[:production_centre_name]}").name if params.has_key?(:production_centre_name)

#    intention = Intention.find_by_name(params[:intention]).name if params.has_keys?(:intention)

#    if intention.blank?
#      raise 'error'
#    elsif intention = 'Mouse Production'
#      ['Mouse Production', 'ES Cell Micro Injection', 'CRIPSR Micro Injection']
#    else
#      intention = [intention]
#    end
#    if ignore_warnings == false && gene_found_and_missing['missing'].length > 0
#      error = "The following genes were not found (Maybe you mistyped the Marker Symbol): #{gene_found_and_missing['missing'].to_sentence}"
#    else
#       where_sql = "plan_intentions.assign = false AND plan_intentions.withdrawn = false AND intentions.name IN ('#{intention.join("', '")}') AND centres.name = #{ centre.name }"
#       where_sql << " AND genes.marker_symbol #{'NOT' if inverse_search == true} IN ('#{marker_symbols.join("', '")}'')" unless marker_symbols.blank?
#       plan_intention = PlanIntention.joins(:intention, plan: [:production_centre, :gene]).where(where_sql)
#    end

#    data = { "gene" => plan_intention.marker_symbol,
#             "consortium_name" => plan_intention.consortium_name,
#             "conflict_status" => plan_intention.conflict_reason
#           }

#    respond_to do |format|
#      if error.blank?
#        format.json { render :json => data.to_json}
#      else
#        format.json { render :json => error.to_json}
#      end
#    end
#  end

#  def assigned_genes
#    marker_symbols = params[:marker_symbols].lines.map(&:strip).select{|i|!i.blank?}.uniq if params.has_key?(:marker_symbols)
#    inverse_search = params[:inverse_search] == 'true' ? true : false
#    ignore_warnings = params[:ignore_warnings] == 'true' ? true :false
#    error = ""
#    gene_found_and_missing = validate_marker_symbols(marker_symbols)
#    centre = current_user.production_centre
#    centre = Centre.where("name = #{params[:production_centre_name]}").name if params.has_key?(:production_centre_name)

#    intention = Intention.find_by_name(params[:intention]).name if params.has_keys?(:intention)

#    if intention.blank?
#      raise 'error'
#    elsif intention = 'Mouse Production'
#      ['Mouse Production', 'ES Cell Micro Injection', 'CRIPSR Micro Injection']
#    else
#      intention = [intention]
#    end
#    if ignore_warnings == false && gene_found_and_missing['missing'].length > 0
#      error = "The following genes were not found (Maybe you mistyped the Marker Symbol): #{gene_found_and_missing['missing'].to_sentence}"
#    else
#       where_sql = "plan_intentions.assign = true AND plan_intentions.withdrawn = false AND intentions.name IN ('#{intention.join("', '")}') AND centres.name = #{ centre.name }"
#       where_sql << " AND genes.marker_symbol #{'NOT' if inverse_search == true} IN ('#{marker_symbols.join("', '")}'')" unless marker_symbols.blank?
#       plan_intention = PlanIntention.joins(:intention, plan: [:production_centre, :gene]).where(where_sql)
#    end

#    data = { "gene" => plan_intention.marker_symbol,
#             "consortium_name" => plan_intention.consortium_name,
#             "pipeline" => plan_intention.intention.name,
#             "production_status" => "In Progress",
#             "conflict_status" => plan_intention.conflict_reason
#           }

#    respond_to do |format|
#      if error.blank?
#        format.json { render :json => data.to_json}
#      else
#        format.json { render :json => error.to_json}
#      end
#    end
#  end

# actions
#  def register_interest_in_gene
    # if intention not include (mouse production, CRISPR MOUSE PRODUCTION, ES CELL PRODUCTION) set pipeline = null
    # Check if gene is already registered
      # YES
        # if (pipeline is stated or intention has no pipeline) and withdrawn = false set withdrawn to true
        # else create new plan intention with intention set to 'Mouse Production' if intention is to create mouse.
      # NO
        #create plan and plan intention
#  end

#  def assign_gene

#  end

#  def unassign_gene

#  end

#  def withdraw_gene

#  end

# private methods

#  def validate_marker_symbols(marker_symbols = [])
#    genes = Genes.where("marker_symbols IN ('#{marker_symbols.join(', ')}')").map{|g| g.marker_symbol}
#    gene_found_and_missing = {}
#    if genes.length != marker_symbols.length
      # missing genes
#      gene_found_and_missing['missing'] = marker_symbols - genes
#    end

    # genes found
#    gene_found_and_missing['found'] = genes
#  end
end
