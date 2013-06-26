class NewGeneIntermediateReport < ActiveRecord::Base

  self.table_name = :new_gene_intermediate_report

  include NewGeneIntermediateReport::ReportGenerator

  belongs_to :phenotype_attempt, :primary_key => 'colony_name', :foreign_key => 'phenotype_attempt_colony_name'

end


# == Schema Information
#
# Table name: new_gene_intermediate_report
#
#  id                                           :integer         not null, primary key
#  gene                                         :string(75)      not null
#  consortium                                   :string(255)     not null
#  production_centre                            :string(255)
#  mgi_accession_id                             :string(40)
#  overall_status                               :string(50)
#  mi_attempt_status                            :string(50)
#  phenotype_attempt_status                     :string(50)
#  ikmc_project_id                              :string(255)
#  mutation_sub_type                            :string(100)
#  allele_symbol                                :string(255)
#  genetic_background                           :string(255)
#  mi_attempt_colony_name                       :string(255)
#  mi_attempt_consortium                        :string(255)
#  mi_attempt_production_centre                 :string(255)
#  phenotype_attempt_colony_name                :string(255)
#  micro_injection_in_progress_date             :date
#  chimeras_obtained_date                       :date
#  genotype_confirmed_date                      :date
#  micro_injection_aborted_date                 :date
#  phenotype_attempt_registered_date            :date
#  rederivation_started_date                    :date
#  rederivation_complete_date                   :date
#  cre_excision_started_date                    :date
#  cre_excision_complete_date                   :date
#  phenotyping_started_date                     :date
#  phenotyping_complete_date                    :date
#  phenotype_attempt_aborted_date               :date
#  distinct_genotype_confirmed_es_cells         :integer
#  distinct_old_genotype_confirmed_es_cells     :integer
#  distinct_non_genotype_confirmed_es_cells     :integer
#  distinct_old_non_genotype_confirmed_es_cells :integer
#  total_pipeline_efficiency_gene_count         :integer
#  total_old_pipeline_efficiency_gene_count     :integer
#  gc_pipeline_efficiency_gene_count            :integer
#  gc_old_pipeline_efficiency_gene_count        :integer
#  created_at                                   :datetime
#

