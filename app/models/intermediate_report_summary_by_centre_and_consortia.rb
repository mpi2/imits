class IntermediateReportSummaryByCentreAndConsortia < IntermediateReportBase
  self.table_name = :intermediate_report_summary_by_centre_and_consortia

  acts_as_reportable

  class << self

    def plan_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell'}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => false, 'phenotyping' => false})
    end

    def mi_production_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell'}
      generate_sql(where_clause, {'mi_production' => true, 'allele_mod_production' => false, 'phenotyping' => false})
    end

    def mi_phenotyping_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell', 'phenotyping_approach' => 'micro-injection'}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => false, 'phenotyping' => true})
    end

    def mam_production_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell'}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => true, 'phenotyping' => false})
    end

    def mam_phenotyping_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell', 'phenotyping_approach' => 'mouse allele modification'}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => false, 'phenotyping' => true})
    end

    def phenotyping_summary_include_everything(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell', 'phenotyping_approach' => nil}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => false, 'phenotyping' => true})
    end

  end

end

# == Schema Information
#
# Table name: intermediate_report_summary_by_centre_and_consortia
#
#  id                                     :integer          not null, primary key
#  catagory                               :string(255)      not null
#  approach                               :string(255)      not null
#  allele_type                            :string(255)      not null
#  mi_plan_id                             :integer
#  mi_attempt_id                          :integer
#  modified_mouse_allele_mod_id           :integer
#  mouse_allele_mod_id                    :integer
#  phenotyping_production_id              :integer
#  consortium                             :string(255)
#  production_centre                      :string(255)
#  gene                                   :string(255)
#  mgi_accession_id                       :string(255)
#  mi_attempt_external_ref                :string(255)
#  mi_attempt_colony_name                 :string(255)
#  mouse_allele_mod_colony_name           :string(255)
#  phenotyping_production_colony_name     :string(255)
#  mi_plan_status                         :string(255)
#  gene_interest_date                     :date
#  assigned_date                          :date
#  assigned_es_cell_qc_in_progress_date   :date
#  assigned_es_cell_qc_complete_date      :date
#  aborted_es_cell_qc_failed_date         :date
#  mi_attempt_status                      :string(255)
#  micro_injection_aborted_date           :date
#  micro_injection_in_progress_date       :date
#  chimeras_obtained_date                 :date
#  founder_obtained_date                  :date
#  genotype_confirmed_date                :date
#  mouse_allele_mod_status                :string(255)
#  mouse_allele_mod_registered_date       :date
#  rederivation_started_date              :date
#  rederivation_complete_date             :date
#  cre_excision_started_date              :date
#  cre_excision_complete_date             :date
#  phenotyping_status                     :string(255)
#  phenotyping_registered_date            :date
#  phenotyping_rederivation_started_date  :date
#  phenotyping_rederivation_complete_date :date
#  phenotyping_experiments_started_date   :date
#  phenotyping_started_date               :date
#  phenotyping_complete_date              :date
#  phenotype_attempt_aborted_date         :date
#  created_at                             :date
#
# Indexes
#
#  irscc_allele_type              (allele_type)
#  irscc_approach                 (approach)
#  irscc_catagory                 (catagory)
#  irscc_mi_attempts              (mi_attempt_id)
#  irscc_mi_plans                 (mi_plan_id)
#  irscc_mouse_allele_mods        (mouse_allele_mod_id)
#  irscc_phenotyping_productions  (phenotyping_production_id)
#
