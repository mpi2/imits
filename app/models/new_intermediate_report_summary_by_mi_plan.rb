class NewIntermediateReportSummaryByMiPlan < ActiveRecord::Base
  attr_accessible(
    'mi_plan_id',
    'overall_status',
    'mi_plan_status',
    'mi_attempt_status',
    'phenotype_attempt_status',
    'consortium',
    'production_centre',
    'sub_project',
    'priority',
    'gene',
    'mgi_accession_id',
    'is_bespoke_allele',
    'ikmc_project_id',
    'mutation_sub_type',
    'allele_symbol',
    'genetic_background',
    'mi_attempt_colony_name',
    'mouse_allele_mod_colony_name',
    'production_colony_name',
    'assigned_date',
    'assigned_es_cell_qc_in_progress_date',
    'assigned_es_cell_qc_complete_date',
    'aborted_es_cell_qc_failed_date',
    'micro_injection_in_progress_date',
    'chimeras_obtained_date',
    'genotype_confirmed_date',
    'micro_injection_aborted_date',
    'phenotype_attempt_registered_date',
    'rederivation_started_date',
    'rederivation_complete_date',
    'cre_excision_started_date',
    'cre_excision_complete_date',
    'phenotyping_started_date',
    'phenotyping_experiments_started_date',
    'phenotyping_complete_date',
    'phenotype_attempt_aborted_date',
    'phenotyping_mi_attempt_consortium',
    'phenotyping_mi_attempt_production_centre',
    'tm1b_phenotype_attempt_status',
    'tm1b_phenotype_attempt_registered_date',
    'tm1b_rederivation_started_date',
    'tm1b_rederivation_complete_date',
    'tm1b_cre_excision_started_date',
    'tm1b_cre_excision_complete_date',
    'tm1b_phenotyping_started_date',
    'tm1b_phenotyping_experiments_started_date',
    'tm1b_phenotyping_complete_date',
    'tm1b_phenotype_attempt_aborted_date',
    'tm1b_colony_name',
    'tm1b_phenotyping_production_colony_name',
    'tm1b_phenotyping_mi_attempt_consortium',
    'tm1b_phenotyping_mi_attempt_production_centre',
    'tm1a_phenotype_attempt_status',
    'tm1a_phenotype_attempt_registered_date',
    'tm1a_rederivation_started_date',
    'tm1a_rederivation_complete_date',
    'tm1a_cre_excision_started_date',
    'tm1a_cre_excision_complete_date',
    'tm1a_phenotyping_started_date',
    'tm1a_phenotyping_experiments_started_date',
    'tm1a_phenotyping_complete_date',
    'tm1a_phenotype_attempt_aborted_date',
    'tm1a_colony_name',
    'tm1a_phenotyping_production_colony_name',
    'tm1a_phenotyping_mi_attempt_consortium',
    'tm1a_phenotyping_mi_attempt_production_centre',
    'distinct_genotype_confirmed_es_cells',
    'distinct_old_genotype_confirmed_es_cells',
    'distinct_non_genotype_confirmed_es_cells',
    'distinct_old_non_genotype_confirmed_es_cells',
    'total_pipeline_efficiency_gene_count',
    'total_old_pipeline_efficiency_gene_count',
    'gc_pipeline_efficiency_gene_count',
    'gc_old_pipeline_efficiency_gene_count'
  )
  self.table_name = :new_intermediate_report_summary_by_mi_plan

  include NewIntermediateReportSummaryByMiPlan::ReportGenerator

end











# == Schema Information
#
# Table name: new_intermediate_report_summary_by_mi_plan
#
#  id                                            :integer         not null, primary key
#  mi_plan_id                                    :integer         not null
#  overall_status                                :string(50)
#  mi_plan_status                                :string(50)
#  mi_attempt_status                             :string(50)
#  phenotype_attempt_status                      :string(50)
#  consortium                                    :string(255)     not null
#  production_centre                             :string(255)
#  sub_project                                   :string(255)
#  priority                                      :string(255)
#  gene                                          :string(255)
#  mgi_accession_id                              :string(40)
#  is_bespoke_allele                             :boolean
#  ikmc_project_id                               :string(255)
#  mutation_sub_type                             :string(100)
#  allele_symbol                                 :string(255)
#  genetic_background                            :string(255)
#  mi_attempt_colony_name                        :string(255)
#  mouse_allele_mod_colony_name                  :string(255)
#  production_colony_name                        :string(255)
#  assigned_date                                 :date
#  assigned_es_cell_qc_in_progress_date          :date
#  assigned_es_cell_qc_complete_date             :date
#  aborted_es_cell_qc_failed_date                :date
#  micro_injection_in_progress_date              :date
#  chimeras_obtained_date                        :date
#  genotype_confirmed_date                       :date
#  micro_injection_aborted_date                  :date
#  phenotype_attempt_registered_date             :date
#  rederivation_started_date                     :date
#  rederivation_complete_date                    :date
#  cre_excision_started_date                     :date
#  cre_excision_complete_date                    :date
#  phenotyping_started_date                      :date
#  phenotyping_experiments_started_date          :date
#  phenotyping_complete_date                     :date
#  phenotype_attempt_aborted_date                :date
#  phenotyping_mi_attempt_consortium             :string(255)
#  phenotyping_mi_attempt_production_centre      :string(255)
#  tm1b_phenotype_attempt_status                 :string(255)
#  tm1b_phenotype_attempt_registered_date        :date
#  tm1b_rederivation_started_date                :date
#  tm1b_rederivation_complete_date               :date
#  tm1b_cre_excision_started_date                :date
#  tm1b_cre_excision_complete_date               :date
#  tm1b_phenotyping_started_date                 :date
#  tm1b_phenotyping_experiments_started_date     :date
#  tm1b_phenotyping_complete_date                :date
#  tm1b_phenotype_attempt_aborted_date           :date
#  tm1b_colony_name                              :string(255)
#  tm1b_phenotyping_production_colony_name       :string(255)
#  tm1b_phenotyping_mi_attempt_consortium        :string(255)
#  tm1b_phenotyping_mi_attempt_production_centre :string(255)
#  tm1a_phenotype_attempt_status                 :string(255)
#  tm1a_phenotype_attempt_registered_date        :date
#  tm1a_rederivation_started_date                :date
#  tm1a_rederivation_complete_date               :date
#  tm1a_cre_excision_started_date                :date
#  tm1a_cre_excision_complete_date               :date
#  tm1a_phenotyping_started_date                 :date
#  tm1a_phenotyping_experiments_started_date     :date
#  tm1a_phenotyping_complete_date                :date
#  tm1a_phenotype_attempt_aborted_date           :date
#  tm1a_colony_name                              :string(255)
#  tm1a_phenotyping_production_colony_name       :string(255)
#  tm1a_phenotyping_mi_attempt_consortium        :string(255)
#  tm1a_phenotyping_mi_attempt_production_centre :string(255)
#  distinct_genotype_confirmed_es_cells          :integer
#  distinct_old_genotype_confirmed_es_cells      :integer
#  distinct_non_genotype_confirmed_es_cells      :integer
#  distinct_old_non_genotype_confirmed_es_cells  :integer
#  total_pipeline_efficiency_gene_count          :integer
#  total_old_pipeline_efficiency_gene_count      :integer
#  gc_pipeline_efficiency_gene_count             :integer
#  gc_old_pipeline_efficiency_gene_count         :integer
#  created_at                                    :datetime
#

