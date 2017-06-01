class TargRep::MousemineSearchesController < TargRep::BaseController
  require "intermine/service"
  respond_to :json

# look up next mgi allele id for an allele produced via an endonuclease experiment.
# we need marker_symbol, production centre 
  def mgi_allele_auto_suggest

    if params.has_key?(:colony_name)
      colony = Colony.find_by_name(params[:colony_name].to_s)
    else
      colony = nil
    end

    if colony.blank?
      marker_symbol = params[:marker_symbol] || ''
      if params.has_key?(:labcode)
        labcode = params[:labcode]
      elsif params.has_key?(:production_centre_name)
        labcode = Centre.find_by_name(params[:production_centre_name].to_s).try(:code)
      else
        labcode = nil
      end
    else
      marker_symbol = colony.marker_symbol || ''
      labcode       = colony.mi_plan.production_centre.try(:code)
    end

    mutation_type = params[:mutation_type] || 'Endonuclease-mediated'

    p_pass = true
    data = []

    ## check Params
    if params.has_key?(:colony_name) && colony.blank?
      error = "Invalid Colony Name provided."
      p_pass = false
    elsif marker_symbol.blank? || mutation_type.blank?
      error = "Missing Parameters. 'marker_symbol' and 'mutation_type' are required parameters."
      p_pass = false
    elsif Gene.where("UPPER(genes.marker_symbol) = '#{marker_symbol.upcase}'").blank?
      error = "Invalid 'marker_symbol' provided."
      p_pass = false    
    elsif ! ['Targeted', 'Endonuclease-mediated'].include?(mutation_type)
      error = "Invalid 'mutation_type' parameter. Must be equal to either 'Targeted' or 'Endonuclease-mediated'."
      p_pass = false
    elsif mutation_type == 'Targeted'
      error = "MGI allele symbol Autosuggest currently does not suggest alleles for 'Targeted' alleles."
      p_pass = false
    elsif labcode.blank?
      error = "Labcode required. Please provide the iMITS admin with your centre's Labcode or add the labcode_overide parameter."
      p_pass = false
    end


    if p_pass && mutation_type == 'Endonuclease-mediated'
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
          data << data_hash if md[4] == labcode
        end
      end

    

      sql = <<-EOF
        (SELECT alleles.mgi_allele_symbol_superscript
        FROM alleles
          JOIN colonies ON colonies.id = alleles.colony_id
          JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
          JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
          JOIN genes ON genes.id = mi_plans.gene_id
          WHERE UPPER(genes.marker_symbol) = '#{marker_symbol.upcase}'
        )
        UNION
        (SELECT alleles.mgi_allele_symbol_superscript
        FROM alleles
          JOIN colonies ON colonies.id = alleles.colony_id
          JOIN mouse_allele_mods ON mouse_allele_mods.id = colonies.mi_attempt_id
          JOIN mi_plans ON mi_plans.id = mouse_allele_mods.mi_plan_id
          JOIN genes ON genes.id = mi_plans.gene_id
          WHERE UPPER(genes.marker_symbol) = '#{marker_symbol.upcase}'
        )
      EOF

      imits_mgi_accession_ids = ActiveRecord::Base.connection.execute(sql).map{|row| row["mgi_allele_symbol_superscript"]}.select{|a| !a.blank?}.uniq
      imits_mgi_accession_ids.each do |s|
        md = /\A(em)(\d+)(\(\w+\))?(\w+)\Z/.match(s)
        if md
          data_hash = {}
          data_hash['allele_superscript'] = marker_symbol + md[0]
          data_hash['mutation_type_suffix'] = md[1]
          data_hash['serial_number'] = md[2]
          data_hash['project_id'] = md[3]
          data_hash['Labcode'] = md[4]
          data << data_hash if md[4] == labcode
        end
      end

      next_symbol_in_sequence = {}
      if data.blank?
        next_symbol_in_sequence['without_impc_abbreviation'] = 'em1' + labcode
        next_symbol_in_sequence['with_impc_abbreviation'] = 'em1(IMPC)' + labcode
      else
        last_allele_symbol = data.sort{|a1, a2| a2["serial_number"] <=> a1["serial_number"]}[0]
        next_symbol_in_sequence['without_impc_abbreviation'] = 'em' + (last_allele_symbol['serial_number'].to_i + 1).to_s + labcode
        next_symbol_in_sequence['with_impc_abbreviation'] = 'em' + (last_allele_symbol['serial_number'].to_i + 1).to_s + '(IMPC)' + labcode
      end

    end

    respond_to do |format|
      if error.blank?
        format.json { render :json => next_symbol_in_sequence.to_json}
      else
        format.json { render :json => error.to_json}
      end
    end
    
  end
end

