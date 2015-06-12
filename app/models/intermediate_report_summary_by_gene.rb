class IntermediateReportSummaryByGene < ActiveRecord::Base
  self.table_name = :intermediate_report_summary_by_gene

  acts_as_reportable

  class << self

    def es_cell_and_crsipr_sql
      <<-EOF
        SELECT intermediate_report_summary_by_gene.*
        FROM intermediate_report_summary_by_gene
        WHERE approach = 'all'
      EOF
    end

    def es_cell_sql
      <<-EOF
        SELECT intermediate_report_summary_by_gene.*
        FROM intermediate_report_summary_by_gene
        WHERE catagory = 'es cell' AND approach = 'all'
      EOF
    end

    def crispr_sql
      <<-EOF
        SELECT intermediate_report_summary_by_gene.*
        FROM intermediate_report_summary_by_gene
        WHERE catagory = 'crispr' AND approach = 'all'
      EOF
    end
  end
end

# == Schema Information
#
# Table name: intermediate_report_summary_by_gene
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
#  gene                                   :string(255)
#  mgi_accession_id                       :string(255)
#  mi_attempt_external_ref                :string(255)
#  mi_attempt_colony_name                 :string(255)
#  mouse_allele_mod_colony_name           :string(255)
#  phenotyping_production_colony_name     :string(255)
#  mi_plan_status                         :string(255)
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
#  irsg_allele_type              (allele_type)
#  irsg_approach                 (approach)
#  irsg_catagory                 (catagory)
#  irsg_mi_attempts              (mi_attempt_id)
#  irsg_mi_plans                 (mi_plan_id)
#  irsg_mouse_allele_mods        (mouse_allele_mod_id)
#  irsg_phenotyping_productions  (phenotyping_production_id)
#
