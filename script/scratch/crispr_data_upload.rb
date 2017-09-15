class CrisprDataUpload

  def initialize(upload_file)
    raise "Please specify upload file" if upload_file.blank?

    @cripsr_file = CSV.open(upload_file)
    @columns = @cripsr_file.readline

    @mi_attempts_to_delete = []
    @f1_count_mismatches = []
    @donor_count_mismatches = []
    @reagent_count_mismatches = []
    @value_mismatch = []
    @stamp_date_mismatch = []
    @grna_sequence_mismatch = []
    @data_uploaded = false
    @status_stamps_uploaded = false
  end

  def columns
    @columns
  end
  
  def mi_attempts_to_delete
    @mi_attempts_to_delete
  end
  
  def f1_count_mismatches
    @f1_count_mismatches
  end
  
  def donor_count_mismatches
    @donor_count_mismatches
  end
  
  def reagent_count_mismatches
    @reagent_count_mismatches
  end
  
  def value_mismatch
    @value_mismatch
  end
  
  def stamp_date_mismatch
    @stamp_date_mismatch
  end
  
  def grna_sequence_mismatch
    @grna_sequence_mismatch
  end

  def read_data
    
    @cripsr_file.each do |row|
      next if row[columns.find_index("mi_attempt_id")].blank?
    
      mi_attempt = MiAttempt.find_by_id(row[columns.find_index("mi_attempt_id")])
      next if mi_attempt.blank? && row[columns.find_index("Delete")] == 'Yes'
      raise "Mi Attempt is missing #{row[columns.find_index("mi_attempt_id")]}" if mi_attempt.blank?
    
      mutagenesis_factor = mi_attempt.mutagenesis_factor
      crisprs = mutagenesis_factor.crisprs
      status_stamps = mi_attempt.status_stamps
    
    
      @mi_attempts_to_delete << row if row[columns.find_index("Delete")] == 'Yes'
      
    
    
      colonies = Colony.where("mi_attempt_id = #{row[columns.find_index("mi_attempt_id")].to_i} AND genotype_confirmed = true")
      f1_count = row[columns.find_index("genotype_confirmed_f1s")].to_i
      @f1_count_mismatches << [row, colonies.count, f1_count] if (colonies.blank? && f1_count.to_i != 0) || (!colonies.blank? && colonies.count < f1_count)
      @donor_count_mismatches << [row, row[columns.find_index("templates_per_gene")].to_i, mutagenesis_factor.donors.count] if !row[columns.find_index("templates_per_gene")].blank? && mutagenesis_factor.donors.count != row[columns.find_index("templates_per_gene")].to_i
      @donor_count_mismatches << [row, row[columns.find_index("template_conc")].to_f, mutagenesis_factor.donors.map{|a| a.concentration}] if !row[columns.find_index("template_conc")].blank? && mutagenesis_factor.donors.count != row[columns.find_index("template_conc")].split(',').length

      @reagent_count_mismatches << [row, row[columns.find_index("reagents")].to_i, mi_attempt.reagents.count] if !row[columns.find_index("reagents")].blank? && mi_attempt.reagents.count != row[columns.find_index("reagents")].to_i  
      @reagent_count_mismatches << [row, row[columns.find_index("reagents_conc")].to_f, mi_attempt.reagents.map{|a| a.concentration}] if !row[columns.find_index("reagents_conc")].blank? && mi_attempt.reagents.count != row[columns.find_index("reagents_conc")].split(',').length
    
      grnas = row[columns.find_index("grna_sequences")].split(',').map{|a| a.strip}
      grnas_coodinates = row[columns.find_index("grna_coordinates")].split(',').map{|a| a.strip.split('-').map{|a| a.to_i}}
      grnas_concentrations = row[columns.find_index("grna_conc")].to_s.split(',').map{|a| a.strip.to_f}
      missing = []
      start_mismatch = []
      end_mismatch = []
      additional = []
      concentration_mismatch = []
      for i in 0..(grnas.length - 1)
        unless crisprs.map{|a| a.sequence}.include?(grnas[i])
          missing << [grnas[i], grnas_coodinates[i]] 
          next
        end
        start_mismatch << [crisprs.select{|a| a["sequence"] == grnas[i]}, grnas[i], grnas_coodinates[i][0]] if crisprs.select{|a| a["sequence"] == grnas[i]}.first["start"] != grnas_coodinates[i][0]
        end_mismatch << [crisprs.select{|a| a["sequence"] == grnas[i]}, grnas[i], grnas_coodinates[i][1]] if crisprs.select{|a| a["sequence"] == grnas[i]}.first["end"] != grnas_coodinates[i][1]
        if mutagenesis_factor.individually_set_grna_concentrations
          concentration_mismatch << [crisprs.select{|a| a["sequence"] == grnas[i]}, mutagenesis_factor.individually_set_grna_concentrations, crisprs.select{|a| a["sequence"] == grnas[i]}.first["grna_concentration"], grnas_concentrations[i]] if crisprs.select{|a| a["sequence"] == grnas[i]}.first["grna_concentration"] != grnas_concentrations[i]
        end
      end

      if mutagenesis_factor.individually_set_grna_concentrations == false && !grnas_concentrations.blank?
        if grnas_concentrations.length > 1
          concentration_mismatch << ["Incorrect number of concentrations given"]
        end
        concentration_mismatch << [mutagenesis_factor.individually_set_grna_concentrations, mutagenesis_factor.grna_concentration, grnas_concentrations.first] if grnas_concentrations.first != mutagenesis_factor.grna_concentration
      end
    
      crisprs.each do |c|
        additional << c unless grnas.include?(c.sequence)
      end
      
      compile_grna_sequence_mismatch = {}
      compile_grna_sequence_mismatch['grna missing'] = missing unless missing.blank?
      compile_grna_sequence_mismatch['grna start coordinate mismatch'] = start_mismatch unless start_mismatch.blank?
      compile_grna_sequence_mismatch['grna end coordinate mismatch'] = end_mismatch unless end_mismatch.blank?
      compile_grna_sequence_mismatch['additional gRNA detected'] = additional unless additional.blank?
      compile_grna_sequence_mismatch['concentration mismatch'] = concentration_mismatch unless concentration_mismatch.blank?
      @grna_sequence_mismatch << [mi_attempt, compile_grna_sequence_mismatch] unless compile_grna_sequence_mismatch.blank?
    
      mi_date = row[columns.find_index("mi_date")].to_s.to_date
      g0_date = row[columns.find_index("g0_obtained_date")].to_s.to_date
      glt_date = row[columns.find_index("genotype_confirmed_date")].to_s.to_date
      aborted_date = row[columns.find_index("Micro-injection aborted date")].to_s.to_date
    
      changed_values = {}
      changed_values["is_active"] = [false, true] if !aborted_date.blank? && mi_attempt.is_active
      mi_date = row[columns.find_index("mi_date")]
      changed_values["mi_date"] = [mi_attempt.mi_date, mi_date] if mi_attempt.mi_date.to_date != mi_date.to_date
      delivery_method = row[columns.find_index("delivery_method")]
      changed_values["delivery_method"] = [mi_attempt.delivery_method, delivery_method] if (!delivery_method.blank? && mi_attempt.delivery_method.blank?) || (!delivery_method.blank? && !mi_attempt.delivery_method.blank? && delivery_method != mi_attempt.delivery_method)
      embryo_transfer_day = row[columns.find_index("embryo_transfer_day")]
      changed_values["crsp_embryo_transfer_day"] = [mi_attempt.crsp_embryo_transfer_day, embryo_transfer_day] if (!embryo_transfer_day.blank? && mi_attempt.crsp_embryo_transfer_day.blank?) || (!embryo_transfer_day.blank? && !mi_attempt.crsp_embryo_transfer_day.blank? && embryo_transfer_day != mi_attempt.crsp_embryo_transfer_day)
      embryos_survived_to_2_cell = row[columns.find_index("embryos_survived_to_2_cell")]
      changed_values["crsp_embryo_2_cell"] = [mi_attempt.crsp_embryo_2_cell, embryos_survived_to_2_cell.to_i]  if (!embryos_survived_to_2_cell.blank? && embryos_survived_to_2_cell.to_i != mi_attempt.crsp_embryo_2_cell.to_i)
      e_injected = row[columns.find_index("e_injected")]
      changed_values["crsp_total_embryos_injected"] = [mi_attempt.crsp_total_embryos_injected, e_injected.to_i] if (!e_injected.blank? && mi_attempt.crsp_total_embryos_injected.blank?) || (!e_injected.blank? && e_injected.to_i != mi_attempt.crsp_total_embryos_injected.to_i)
      embryos_survived = row[columns.find_index("embryos_survived")]
      changed_values["crsp_total_embryos_survived"] = [mi_attempt.crsp_total_embryos_survived, embryos_survived.to_i] if (!embryos_survived.blank? && mi_attempt.crsp_total_embryos_survived.blank?) || (!embryos_survived.blank? && embryos_survived.to_i != mi_attempt.crsp_total_embryos_survived.to_i)
      e_transferred = row[columns.find_index("e_transferred")]
      changed_values["crsp_total_transfered"] = [mi_attempt.crsp_total_transfered, e_transferred.to_i] if (!e_transferred.blank? && mi_attempt.crsp_total_transfered.blank?) || (!e_transferred.blank? && e_transferred.to_i != mi_attempt.crsp_total_transfered.to_i)
      pups_born = row[columns.find_index("pups_born")]
      changed_values["crsp_no_founder_pups"] = [mi_attempt.crsp_no_founder_pups, pups_born.to_i] if (!pups_born.blank? && mi_attempt.crsp_no_founder_pups.blank?) || (!pups_born.blank? && pups_born.to_i != mi_attempt.crsp_no_founder_pups.to_i)
      cas9_d10a = row[columns.find_index("cas9_d10a")].upcase
      mrna_protein = row[columns.find_index("mrna_protein")]
      if mrna_protein == 'mrna'
        changed_values["mrna_nuclease"] = [mi_attempt.mrna_nuclease, cas9_d10a] if (!cas9_d10a.blank? && mi_attempt.mrna_nuclease.blank?) || (!cas9_d10a.blank? && !mi_attempt.mrna_nuclease.blank? && cas9_d10a != mi_attempt.mrna_nuclease)
      elsif mrna_protein == 'protein'
        changed_values["protein_nuclease"] = [mi_attempt.protein_nuclease, cas9_d10a] if (!cas9_d10a.blank? && mi_attempt.protein_nuclease.blank?) || (!cas9_d10a.blank? && !mi_attempt.protein_nuclease.blank? && cas9_d10a != mi_attempt.protein_nuclease)
      end
      mrna_nuclease_conc = row[columns.find_index("mrna_nuclease_conc")]
      changed_values["mrna_nuclease_concentration"] = [mi_attempt.mrna_nuclease_concentration, mrna_nuclease_conc.to_f] if (!mrna_nuclease_conc.blank? && mi_attempt.mrna_nuclease_concentration.blank?) || (!mrna_nuclease_conc.blank? && mrna_nuclease_conc.to_f != mi_attempt.mrna_nuclease_concentration.to_f)
      protein_nuclease_conc = row[columns.find_index("protein_nuclease_conc")]
      changed_values["protein_nuclease_concentration"] = [mi_attempt.protein_nuclease_concentration, protein_nuclease_conc.to_f] if (!protein_nuclease_conc.blank? && mi_attempt.protein_nuclease_concentration.blank?) || (!protein_nuclease_conc.blank? && protein_nuclease_conc.to_f != mi_attempt.protein_nuclease_concentration.to_f)
      go_screened = row[columns.find_index("go_screened")]
      changed_values["founder_num_assays"] = [mi_attempt.founder_num_assays, go_screened.to_i] if (!go_screened.blank? && mi_attempt.founder_num_assays.blank?) || (!go_screened.blank? && go_screened.to_i != mi_attempt.founder_num_assays.to_i)
    
      g0_bred = row[columns.find_index("g0_bred")]
      changed_values["crsp_num_founders_selected_for_breading"] = [mi_attempt.crsp_num_founders_selected_for_breading, g0_bred.to_i] if (!g0_bred.blank? && mi_attempt.crsp_num_founders_selected_for_breading.blank?) || (!g0_bred.blank? && g0_bred.to_i != mi_attempt.crsp_num_founders_selected_for_breading.to_i)
    
      g0_with_indel = row[columns.find_index("g0_with_nhej_mutation")]
      g0_with_deletion = row[columns.find_index("g0_with_deletion_mutation")]
      g0_with_hr = row[columns.find_index("g0_with_hr_mutation")]
      g0_with_hdr = row[columns.find_index("g0_with_hdr_mutation")]
      g0_with_all_donors = row[columns.find_index("g0_all_donors_inserted")]
      g0_with_subset_donors = row[columns.find_index("g0_subset_of_donors_inserted")]

      changed_values["no_nhej_g0_mutants"] = [mutagenesis_factor.no_nhej_g0_mutants, g0_with_indel.to_i] if (!g0_with_indel.blank? && mutagenesis_factor.no_nhej_g0_mutants.blank?) || (!g0_with_indel.blank? && g0_with_indel.to_i != mutagenesis_factor.no_nhej_g0_mutants.to_s.to_i)
      changed_values["no_deletion_g0_mutants"] = [mutagenesis_factor.no_deletion_g0_mutants, g0_with_deletion.to_i] if (!g0_with_deletion.blank? && mutagenesis_factor.no_deletion_g0_mutants.blank?) || (!g0_with_deletion.blank? && g0_with_deletion.to_i != mutagenesis_factor.no_deletion_g0_mutants.to_s.to_i)
      changed_values["no_hr_g0_mutants"] = [mutagenesis_factor.no_hr_g0_mutants, g0_with_hr.to_i] if (!g0_with_hr.blank? && mutagenesis_factor.no_hr_g0_mutants.blank?) || (!g0_with_hr.blank? && g0_with_hr.to_i != mutagenesis_factor.no_hr_g0_mutants.to_s.to_i)
      changed_values["no_hdr_g0_mutants"] = [mutagenesis_factor.no_hdr_g0_mutants, g0_with_hdr.to_i] if (!g0_with_hdr.blank? && mutagenesis_factor.no_hdr_g0_mutants.blank?) || (!g0_with_hdr.blank? && g0_with_hdr.to_i != mutagenesis_factor.no_hdr_g0_mutants.to_s.to_i)
      changed_values["no_hdr_g0_mutants_all_donors_inserted"] = [mutagenesis_factor.no_hdr_g0_mutants_all_donors_inserted, g0_with_all_donors.to_i] if (!g0_with_all_donors.blank? && mutagenesis_factor.no_hdr_g0_mutants_all_donors_inserted.blank?) || (!g0_with_all_donors.blank? && g0_with_all_donors.to_i != mutagenesis_factor.no_hdr_g0_mutants_all_donors_inserted.to_s.to_i)
      changed_values["no_hdr_g0_mutants_subset_donors_inserted"] = [mutagenesis_factor.no_hdr_g0_mutants_subset_donors_inserted, g0_with_subset_donors.to_i] if (!g0_with_subset_donors.blank? && mutagenesis_factor.no_hdr_g0_mutants_subset_donors_inserted.blank?) || (!g0_with_subset_donors.blank? && g0_with_subset_donors.to_i != mutagenesis_factor.no_hdr_g0_mutants_subset_donors_inserted.to_s.to_i)

      @value_mismatch << [mi_attempt, changed_values] unless changed_values.blank?
    
      @data_uploaded = true
    end
  end

  def update_changed_values
    raise "Please read data before updating values" unless @data_uploaded

    ## UPDATE values as pm9
    Audit.as_user(User.find_by_email('pm9@ebi.ac.uk')) do
      update_mutagenesis_factor_attributes
      update_mi_attempt_attributes
    end

    ### NEED TO SAVE NEW VALUES AND RELOAD
    @cripsr_file.rewind
    @cripsr_file.readline ## skip header line
    @cripsr_file.each do |row|
      next if row[columns.find_index("mi_attempt_id")].blank?
    
      mi_attempt = MiAttempt.find_by_id(row[columns.find_index("mi_attempt_id")])
      next if row[columns.find_index("Delete")] == 'Yes'
      raise "Mi Attempt is missing #{row[columns.find_index("mi_attempt_id")]}" if mi_attempt.blank?

      status_stamps = mi_attempt.status_stamps
      stamp_date_mismatch = {}

      ss_in_progress = status_stamps.select{|ss| ss.status.name == 'Micro-injection in progress'}.first.try(:created_at).to_s.to_datetime
      ss_ch_g0 = status_stamps.select{|ss| ss.status.name == 'Chimeras/Founder obtained'}.first.try(:created_at).to_s.to_datetime
      ss_founder = status_stamps.select{|ss| ss.status.name == 'Founder obtained'}.first.try(:created_at).to_s.to_datetime
      ss_glt = status_stamps.select{|ss| ss.status.name == 'Genotype confirmed'}.first.try(:created_at).to_s.to_datetime
      ss_aborted = status_stamps.select{|ss| ss.status.name == 'Micro-injection aborted'}.first.try(:created_at).to_s.to_datetime

      mi_date = row[columns.find_index("mi_date")].to_s.to_datetime
      g0_date = row[columns.find_index("g0_obtained_date")].to_s.to_datetime
      glt_date = row[columns.find_index("genotype_confirmed_date")].to_s.to_datetime
      aborted_date = row[columns.find_index("Micro-injection aborted date")].to_s.to_datetime

      
      stamp_date_mismatch['mi_date mismatch'] = [ss_in_progress, mi_date] if ss_in_progress != mi_date
      stamp_date_mismatch['g0 obtained mismatch'] = [ss_founder, g0_date] if (ss_founder.blank? && !g0_date.blank?) || (!ss_founder.blank? && !g0_date.blank? && ss_founder.to_date != g0_date.to_date)
      stamp_date_mismatch['chim g0 mismatch'] = [ss_ch_g0, g0_date] if (ss_founder.blank? && !g0_date.blank?) || (!ss_founder.blank? && !g0_date.blank? && ss_founder.to_date != g0_date.to_date)
      stamp_date_mismatch['glt mismatch'] = [ss_glt, glt_date] if (ss_glt.blank? && !glt_date.blank?) || (!ss_glt.blank? && !glt_date.blank? && ss_glt.to_date != glt_date.to_date)
      stamp_date_mismatch['aborted mismatch'] = [ss_aborted, aborted_date] if (ss_aborted.blank? && !aborted_date.blank?) || (!ss_aborted.blank? && !aborted_date.blank? && ss_aborted.to_date != aborted_date.to_date)

      @stamp_date_mismatch << [mi_attempt, stamp_date_mismatch] unless stamp_date_mismatch.blank?
    end

    @status_stamps_uploaded = true
  end

  def delete_marked_mi_attempt
    raise "Please read data before updating values" unless @data_uploaded
    ## UPDATE values as pm9
    Audit.as_user(User.find_by_email('pm9@ebi.ac.uk')) do
      mi_attempts_to_delete.each do |row|
        mi_attempt = MiAttempt.find(row[columns.find_index("mi_attempt_id")])
        mi_attempt.destroy
      end
    end
  end

  def update_crispr_attributes
    grna_sequence_mismatch.each do |mi_attempt, grna_data|
      mf = MutagenesisFactor.find(mi_attempt.mutagenesis_factor_id)

      grna_data['concentration mismatch'].select{|a| a[0] == false}.each do |row|
        mf.grna_concentration = row[2]
        mf.individually_set_grna_concentrations = false

        mf.save
      end
    end
    return true
  end

  def update_mutagenesis_factor_attributes
    mutagenesis_factor_attributes = ["no_nhej_g0_mutants", "no_deletion_g0_mutants", "no_hdr_g0_mutants_all_donors_inserted", "no_hdr_g0_mutants_subset_donors_inserted", "no_hr_g0_mutants", "no_hdr_g0_mutants"]

    value_mismatch.each do |mi_attempt, changed_values|

      att_to_update = changed_values.select{|k, v| mutagenesis_factor_attributes.include?(k)}
      att_to_update.each{|k, v| att_to_update[k]=v[1]}
      next if att_to_update.blank?
      mf = MutagenesisFactor.find(mi_attempt.mutagenesis_factor_id)

      mf.no_nhej_g0_mutants = att_to_update["no_nhej_g0_mutants"] if att_to_update.has_key?("no_nhej_g0_mutants")
      mf.no_deletion_g0_mutants = att_to_update["no_deletion_g0_mutants"] if att_to_update.has_key?("no_deletion_g0_mutants")
      mf.no_hr_g0_mutants = att_to_update["no_hr_g0_mutants"] if att_to_update.has_key?("no_hr_g0_mutants")
      mf.no_hdr_g0_mutants = att_to_update["no_hdr_g0_mutants"] if att_to_update.has_key?("no_hdr_g0_mutants")
      mf.no_hdr_g0_mutants_all_donors_inserted = att_to_update["no_hdr_g0_mutants_all_donors_inserted"] if att_to_update.has_key?("no_hdr_g0_mutants_all_donors_inserted")
      mf.no_hdr_g0_mutants_subset_donors_inserted = att_to_update["no_hdr_g0_mutants_subset_donors_inserted"] if att_to_update.has_key?("no_hdr_g0_mutants_subset_donors_inserted")

      mf.save
    end
    
  end
  private :update_mutagenesis_factor_attributes

  def update_mi_attempt_attributes
    mi_attempt_attributes = ["delivery_method", "crsp_embryo_transfer_day", "crsp_embryo_2_cell", "founder_num_assays", "crsp_total_embryos_injected", "mi_date", "crsp_num_founders_selected_for_breading", "crsp_total_embryos_survived", "crsp_no_founder_pups", "crsp_total_transfered", "protein_nuclease_concentration", "protein_nuclease", "mrna_nuclease", "mrna_nuclease_concentration"]

    value_mismatch.each do |mi, changed_values|
      mi_attempt = MiAttempt.find(mi.id)
      att_to_update = changed_values.select{|k, v| mi_attempt_attributes.include?(k)}
      att_to_update.each{|k, v| att_to_update[k]=v[1]}
      mi_attempt.update_attributes(att_to_update)
    end

  end
  private :update_mi_attempt_attributes

  def update_status_stamp_values
    raise "Please update changed values before updating status stamp values" unless @status_stamps_uploaded

    ## UPDATE values as pm9
    Audit.as_user(User.find_by_email('pm9@ebi.ac.uk')) do
      stamp_date_mismatch.each do |mi_attempt, changed_date|
        status_stamps = mi_attempt.status_stamps
        changed_date.each do |key, value|
          ss = nil
          case key
          when "g0 obtained mismatch"
            ss = status_stamps.find_by_status_id(5)
            next if ss.blank?
          when "chim g0 mismatch"
            ss = status_stamps.find_by_status_id(6)
            next if ss.blank?
          when "glt mismatch"
            ss = status_stamps.find_by_status_id(2)
            next if ss.blank?
          when "aborted mismatch"
            ss = status_stamps.find_by_status_id(3)
            next if ss.blank?
          end

          ss.created_at = value[1]
          raise "Could not save status stamp: #{ss.errors.messages}" unless ss.save
        end
      end
    end
  end


end
