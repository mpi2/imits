class Public::MiAttempt < ::MiAttempt

  include ::Public::Serializable
  include ::ApplicationModel::BelongsToMiPlan::Public

  FULL_ACCESS_ATTRIBUTES = %w{
    es_cell_name
    mi_date
    consortium_name
    production_centre_name
    parent_colony_name
    blast_strain_name
    total_blasts_injected
    total_transferred
    number_surrogates_receiving
    total_pups_born
    total_female_chimeras
    total_male_chimeras
    total_chimeras
    number_of_males_with_0_to_39_percent_chimerism
    number_of_males_with_40_to_79_percent_chimerism
    number_of_males_with_80_to_99_percent_chimerism
    number_of_males_with_100_percent_chimerism
    test_cross_strain_name
    date_chimeras_mated
    number_of_chimera_matings_attempted
    number_of_chimera_matings_successful
    number_of_chimeras_with_glt_from_cct
    number_of_chimeras_with_glt_from_genotyping
    number_of_chimeras_with_0_to_9_percent_glt
    number_of_chimeras_with_10_to_49_percent_glt
    number_of_chimeras_with_50_to_99_percent_glt
    number_of_chimeras_with_100_percent_glt
    total_f1_mice_from_matings
    number_of_cct_offspring
    number_of_het_offspring
    number_of_live_glt_offspring
    report_to_public
    is_active
    comments
    mi_plan_id
    mutagenesis_factor_id
    cassette_transmission_verified
    cassette_transmission_verified_auto_complete
    mrna_nuclease
    mrna_nuclease_concentration
    protein_nuclease
    protein_nuclease_concentration
    delivery_method
    voltage
    number_of_pulses 
    crsp_total_embryos_injected
    crsp_total_embryos_survived
    crsp_total_transfered
    crsp_no_founder_pups
    founder_num_assays
    assay_type
    crsp_embryo_transfer_day 
    crsp_embryo_2_cell 
    crsp_num_founders_selected_for_breading
    external_ref
    experimental
    colonies_attributes
    reagents_attributes
    mutagenesis_factor_attributes
    g0_screens_attributes
    status_stamps_attributes
    haplo_essential
  }

  READABLE_ATTRIBUTES = %w{
    id
    mi_plan_mutagenesis_via_crispr_cas9
    es_cell_marker_symbol
    marker_symbol
    es_cell_allele_symbol
    status_name
    status_dates
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    pipeline_name
    blast_strain_mgi_accession
    blast_strain_mgi_name
    test_cross_strain_mgi_accession
    test_cross_strain_mgi_name
    mgi_accession_id
    genotyped_confirmed_colony_names
    genotyped_confirmed_colony_phenotype_attempts_count
    genotype_confirmed_allele_symbols
    genotype_confirmed_distribution_centres

  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  def status_name; status.name; end

  def status_dates
    retval = reportable_statuses_with_latest_dates
    retval.each do |status_name, date|
      retval[status_name] = date.to_s
    end
    return retval
  end

  def pipeline_name
    try(:es_cell).try(:pipeline).try(:name)
  end

  def genotyped_confirmed_colony_names
    return [] if colonies.blank? || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.name}.join(',') + ']'
  end

  def genotyped_confirmed_colony_phenotype_attempts_count
    return [] if colonies.blank? || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.phenotype_attempts_count}.join(',') + ']'
  end

  def genotype_confirmed_allele_symbols
    return [] if colonies.blank? || self.id.blank?
    colony_alleles = Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.alleles.map{|a| a.mgi_allele_symbol_superscript}.join('')}.join(',')
    if !colony_alleles.blank?
      return '[' + self.marker_symbol + '<sup>' + colony_alleles + '</sup>' + ']'
    else
      return []
    end
  end

  def genotype_confirmed_distribution_centres
    return [] if colonies.blank? || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.distribution_centres.count > 0 ? c.distribution_centres_formatted_display : '[]'}.join(',') + ']'

  end

  def mutagenesis_factor_attributes
    json_options = {
    :methods => ['crisprs_attributes', 'donors_attributes', 'genotype_primers_attributes']
    }
    return mutagenesis_factor.as_json(json_options)
  end

  def g0_screens_attributes
    json_options = {
    :only => ['no_g0_where_mutation_detected', 'no_nhej_g0_mutants', 'no_deletion_g0_mutants', 'no_hr_g0_mutants',
              'no_hdr_g0_mutants', 'no_hdr_g0_mutants_all_donors_inserted', 'no_hdr_g0_mutants_subset_donors_inserted'],
    :methods => ['marker_symbol']
    }
    mutagenesis_factor.as_json(json_options)
  end
end

# == Schema Information
#
# Table name: mi_attempts
#
#  id                                              :integer          not null, primary key
#  es_cell_id                                      :integer
#  mi_date                                         :date             not null
#  status_id                                       :integer          not null
#  external_ref                                    :string(125)
#  updated_by_id                                   :integer
#  blast_strain_id                                 :integer
#  total_blasts_injected                           :integer
#  total_transferred                               :integer
#  number_surrogates_receiving                     :integer
#  total_pups_born                                 :integer
#  total_female_chimeras                           :integer
#  total_male_chimeras                             :integer
#  total_chimeras                                  :integer
#  number_of_males_with_0_to_39_percent_chimerism  :integer
#  number_of_males_with_40_to_79_percent_chimerism :integer
#  number_of_males_with_80_to_99_percent_chimerism :integer
#  number_of_males_with_100_percent_chimerism      :integer
#  test_cross_strain_id                            :integer
#  date_chimeras_mated                             :date
#  number_of_chimera_matings_attempted             :integer
#  number_of_chimera_matings_successful            :integer
#  number_of_chimeras_with_glt_from_cct            :integer
#  number_of_chimeras_with_glt_from_genotyping     :integer
#  number_of_chimeras_with_0_to_9_percent_glt      :integer
#  number_of_chimeras_with_10_to_49_percent_glt    :integer
#  number_of_chimeras_with_50_to_99_percent_glt    :integer
#  number_of_chimeras_with_100_percent_glt         :integer
#  total_f1_mice_from_matings                      :integer
#  number_of_cct_offspring                         :integer
#  number_of_het_offspring                         :integer
#  number_of_live_glt_offspring                    :integer
#  report_to_public                                :boolean          default(TRUE), not null
#  is_active                                       :boolean          default(TRUE), not null
#  comments                                        :text
#  created_at                                      :datetime
#  updated_at                                      :datetime
#  mi_plan_id                                      :integer          not null
#  legacy_es_cell_id                               :integer
#  cassette_transmission_verified                  :date
#  cassette_transmission_verified_auto_complete    :boolean
#  mutagenesis_factor_id                           :integer
#  crsp_total_embryos_injected                     :integer
#  crsp_total_embryos_survived                     :integer
#  crsp_total_transfered                           :integer
#  crsp_no_founder_pups                            :integer
#  crsp_num_founders_selected_for_breading         :integer
#  allele_id                                       :integer
#  founder_num_assays                              :integer
#  assay_type                                      :text
#  experimental                                    :boolean          default(FALSE), not null
#  allele_target                                   :string(255)
#  parent_colony_id                                :integer
#  mrna_nuclease                                   :string(255)
#  mrna_nuclease_concentration                     :float
#  protein_nuclease                                :string(255)
#  protein_nuclease_concentration                  :float
#  delivery_method                                 :string(255)
#  voltage                                         :float
#  number_of_pulses                                :integer
#  crsp_embryo_transfer_day                        :string(255)      default("Same Day")
#  crsp_embryo_2_cell                              :integer
#  haplo_essential                                 :boolean          default(FALSE)
#
# Indexes
#
#  index_mi_attempts_on_colony_name  (external_ref) UNIQUE
#
