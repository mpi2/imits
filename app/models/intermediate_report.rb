class IntermediateReport < ActiveRecord::Base

  def self.generate
    IntermediateReport.transaction do
      IntermediateReport.delete_all

      cached_report = Reports::MiProduction::Intermediate.new.report

      cached_report.each do |row|
        hash = {}
        cached_report.column_names.each { |column_name| hash[column_name.parameterize.underscore.to_sym] = row[column_name] }
        IntermediateReport.create hash
      end
    end
  end
end

# == Schema Information
#
# Table name: intermediate_reports
#
#  id                                           :integer         not null, primary key
#  consortium                                   :string(255)     not null
#  sub_project                                  :string(255)     not null
#  priority                                     :string(255)
#  production_centre                            :string(100)     not null
#  gene                                         :string(75)      not null
#  mgi_accession_id                             :string(40)
#  overall_status                               :string(50)
#  miplan_status                                :string(50)
#  miattempt_status                             :string(50)
#  phenotypeattempt_status                      :string(50)
#  ikmc_project_id                              :integer
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
#  miplan_id                                    :integer
#  created_at                                   :datetime
#  updated_at                                   :datetime
#
