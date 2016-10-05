class TargRep::MousemineSearchesController < TargRep::BaseController
  require "intermine/service"
  respond_to :json

# look up next mgi allele id for an allele produced via an endonuclease experiment.
# we need marker_symbol, production centre 
  def mgi_allele_auto_suggest

    colony = Colony.find_by_name(params[:colony_name].to_s)

    if colony.blank?
      marker_symbol = params[:marker_symbol] || ''
      labcode       = params[:labcode_overide] || Centre.find_by_name(params[:production_centre_name].to_s).try(:code)
    else
      marker_symbol = colony.marker_symbol || ''
      labcode       = colony.mi_plan.production_centre.try(:code)
    end

    without_project_id = params[:without_project_id] == 'true' ? true : false
    allele_type = params[:allele_type] || 'Endonuclease-mediated'

    params_passed = true
    data = []

    ## check Params
    if !params[:colony_name].blank? && colony.blank?
      error = "Invalid Colony Name provided."
      params_passed = false    elsif marker_symbol.blank? || allele_type.blank?
    elsif marker_symbol.blank? || allele_type.blank?
      error = "Missing Parameters. 'marker_symbol' and 'allele_type' are required parameters."
      params_passed = false
    elsif Gene.find_by_marker_symbol(marker_symbol).blank?
      error = "Invalid 'marker_symbol' provided."
      params_passed = false    
    elsif ! ['Targeted', 'Endonuclease-mediated'].include?(allele_type)
      error = "Invalid 'allele_type' parameter. Must be equal to either 'Targeted' or 'Endonuclease-mediated'."
      params_passed = false
    elsif allele_type == 'Targeted'
      error = "MGI allele symbol Autosuggest currently does not suggest alleles for 'Targeted' alleles."
      params_passed = false
    elsif labcode.blank?
      error = "Labcode required. Please provide the iMITS admin with your centre's Labcode or add the labcode_overide parameter."
      params_passed = false
    end

    if params_passed && allele_type == 'Endonuclease-mediated'
      ## check allele_symbols in Colony table for the gene
#      sql = <<-EOF
#        SELECT colonies.mgi_allele_symbol_superscript
#        FROM colonies
#          LEFT JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
#          LEFT JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mouse_allele_mod_id
#          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id OR mi_plans.id = mouse_allele_mods.mi_plan_id
#          JOIN genes ON genes.id = mi_plans.gene_id
#        WHERE genes.marker_symbol = '#{marker_symbol}' AND colonies.mgi_allele_symbol_superscript IS NOT NULL
#      EOF
#
#      Colony.find_by_sql(sql)


      service = Service.new("#{Rails.configuration.mousemine_root}")
  
      query = service.new_query("Allele").
                select(["alleleType", "primaryIdentifier", "symbol", "molecularNote", "feature.symbol"]).
                where("Allele.symbol" => "*<em*>").
                where("Allele.feature.symbol" => "#{marker_symbol}").
                order_by("alleleType", "ASC")
  
      puts query.count
      query.each_row do |s|
        md = /\A\w+<(em)(\d+)(\(\w+\))?(\w+)>\Z/.match(s['symbol'])
        if md
          data_hash = {}
          data_hash['allele_superscript'] = md[0]
          data_hash['mutation_type_suffix'] = md[1]
          data_hash['serial_number'] = md[2]
          data_hash['project_id'] = md[3]
          data_hash['Labcode'] = md[4]
          data << data_hash
        end
      end

    end


    respond_to do |format|
      if error.blank?
        format.json { render :json => data.to_json}
      else
        format.json { render :json => error.to_json}
      end
    end
    
  end
end

