class IntermediateReportSummaryByMiPlan < ActiveRecord::Base
  self.table_name = :intermediate_report_summary_by_mi_plan

  acts_as_reportable

  belongs_to :mi_plan
  belongs_to :mi_attmept
  belongs_to :mouse_allele_mod
  belongs_to :phenotyping_production

  class << self

    def es_cell_and_crsipr_sql
      <<-EOF
        SELECT intermediate_report_summary_by_mi_plan.*
        FROM intermediate_report_summary_by_mi_plan
        WHERE approach = 'all'
      EOF
    end

    def es_cell_sql
      <<-EOF
        SELECT intermediate_report_summary_by_mi_plan.*
        FROM intermediate_report_summary_by_mi_plan
        WHERE catagory = 'es cell' AND approach = 'all'
      EOF
    end

    def crispr_sql
      <<-EOF
        SELECT intermediate_report_summary_by_mi_plan.*
        FROM intermediate_report_summary_by_mi_plan
        WHERE catagory = 'crispr' AND approach = 'all'
      EOF
    end
  end
end

# == Schema Information
#
# Table name: intermediate_report_summary_by_mi_plan
#
#  id                                   :integer          not null, primary key
#  catagory                             :string(255)      not null
#  approach                             :string(255)      not null
#  allele_type                          :string(255)      not null
#  mi_plan_id                           :integer
#  mi_attempt_id                        :integer
#  modified_mouse_allele_mod_id         :integer
#  mouse_allele_mod_id                  :integer
#  phenotyping_production_id            :integer
#  consortium                           :string(255)
#  production_centre                    :string(255)
#  sub_project                          :string(255)
#  priority                             :string(255)
#  gene                                 :string(255)
#  mgi_accession_id                     :string(255)
#  mi_attempt_external_ref              :string(255)
#  mi_attempt_colony_name               :string(255)
#  mouse_allele_mod_colony_name         :string(255)
#  phenotyping_production_colony_name   :string(255)
#  mi_plan_status                       :string(255)
#  assigned_date                        :date
#  assigned_es_cell_qc_in_progress_date :date
#  assigned_es_cell_qc_complete_date    :date
#  aborted_es_cell_qc_failed_date       :date
#  mi_attempt_status                    :string(255)
#  micro_injection_aborted_date         :date
#  micro_injection_in_progress_date     :date
#  chimeras_obtained_date               :date
#  founder_obtained_date                :date
#  genotype_confirmed_date              :date
#  mouse_allele_mod_status              :string(255)
#  mouse_allele_mod_registered_date     :date
#  rederivation_started_date            :date
#  rederivation_complete_date           :date
#  cre_excision_started_date            :date
#  cre_excision_complete_date           :date
#  phenotyping_status                   :string(255)
#  phenotype_attempt_registered_date    :date
#  phenotyping_experiments_started_date :date
#  phenotyping_started_date             :date
#  phenotyping_complete_date            :date
#  phenotype_attempt_aborted_date       :date
#  mi_aborted_count                     :integer
#  mi_aborted_max_date                  :date
#  allele_mod_aborted_count             :integer
#  allele_mod_aborted_max_date          :date
#  created_at                           :date
#
# Indexes
#
#  irsmp_allele_type  (allele_type)
#  irsmp_approach     (approach)
#  irsmp_catagory     (catagory)
#
