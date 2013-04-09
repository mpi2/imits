class IntermediateReport < ActiveRecord::Base
  self.table_name = :intermediate_report

  acts_as_reportable

  ## Class methods

  def self.generate(report)
    IntermediateReport.transaction do
      IntermediateReport.destroy_all
      report.each do |row|
        hash = {}
        report.column_names.each do |column_name|
          hash[column_name.gsub(' - ', '_').gsub(' ', '_').underscore.to_sym] = row[column_name]
          hash[column_name.gsub(' - ', '_').gsub(' ', '_').underscore.to_sym] = row[column_name] == 'Yes' if column_name == 'Is Bespoke Allele'
        end
        IntermediateReport.create hash
      end
    end
  end
  
end

# == Schema Information
#
# Table name: intermediate_report
#
#  id                                           :integer         not null, primary key
#  consortium                                   :string(255)     not null
#  sub_project                                  :string(255)     not null
#  priority                                     :string(255)
#  production_centre                            :string(100)     not null
#  gene                                         :string(75)      not null
#  mgi_accession_id                             :string(40)
#  overall_status                               :string(50)
#  mi_plan_status                               :string(50)
#  mi_attempt_status                            :string(50)
#  phenotype_attempt_status                     :string(50)
#  ikmc_project_id                              :string(255)
#  mutation_sub_type                            :string(100)
#  allele_symbol                                :string(75)      not null
#  genetic_background                           :string(50)      not null
#  assigned_date                                :date
#  assigned_es_cell_qc_in_progress_date         :date
#  assigned_es_cell_qc_complete_date            :date
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
#  distinct_old_non_genotype_confirmed_es_cells :integer
#  mi_plan_id                                   :integer         not null
#  created_at                                   :datetime
#  updated_at                                   :datetime
#  total_pipeline_efficiency_gene_count         :integer
#  gc_pipeline_efficiency_gene_count            :integer
#  is_bespoke_allele                            :boolean
#  aborted_es_cell_qc_failed_date               :date
#  mi_attempt_colony_name                       :string(255)
#  mi_attempt_consortium                        :string(255)
#  mi_attempt_production_centre                 :string(255)
#  phenotype_attempt_colony_name                :string(255)
#

