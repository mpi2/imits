class IntermediateReportSummaryByCentre < ActiveRecord::Base

  extend IntermediateReport::QueryBase

  self.table_name = :intermediate_report_summary_by_centre

  def self.distinct_fields
    return {'centre' => 1
            }
  end

  def self.allele_summary(options)
    where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell',
                    'approach' => 'all',
                    'allele_type' => options.has_key?('allele_type') ? options['allele_type'] : 'not_all'
                   }
    generate_sql(where_clause, {'mi_production' => true, 'allele_mod_production' => false, 'phenotyping' => false, 'show_allele_type' => true})
  end

end

# == Schema Information
#
# Table name: intermediate_report_summary_by_centre
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
#  irscen_allele_type              (allele_type)
#  irscen_approach                 (approach)
#  irscen_catagory                 (catagory)
#  irscen_gene_centre              (gene,production_centre)
#  irscen_mi_attempts              (mi_attempt_id)
#  irscen_mi_plans                 (mi_plan_id)
#  irscen_mouse_allele_mods        (mouse_allele_mod_id)
#  irscen_phenotyping_productions  (phenotyping_production_id)
#
