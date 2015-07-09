class CreateGeneAndCentreIntermediateReports < ActiveRecord::Migration

  def self.up

    create_table :intermediate_report_summary_by_gene do |t|

          t.string   :catagory,     :null => false
          t.string   :approach,     :null => false
          t.string   :allele_type,  :null => false

          t.integer  :mi_plan_id
          t.integer  :mi_attempt_id
          t.integer  :modified_mouse_allele_mod_id
          t.integer  :mouse_allele_mod_id
          t.integer  :phenotyping_production_id

          t.string   :gene
          t.string   :mgi_accession_id

          t.string   :mi_attempt_external_ref
          t.string   :mi_attempt_colony_name
          t.string   :mouse_allele_mod_colony_name
          t.string   :phenotyping_production_colony_name

          t.string   :mi_plan_status
          t.date     :assigned_date
          t.date     :assigned_es_cell_qc_in_progress_date
          t.date     :assigned_es_cell_qc_complete_date
          t.date     :aborted_es_cell_qc_failed_date

          t.string   :mi_attempt_status
          t.date     :micro_injection_aborted_date
          t.date     :micro_injection_in_progress_date
          t.date     :chimeras_obtained_date
          t.date     :founder_obtained_date
          t.date     :genotype_confirmed_date

          t.string   :mouse_allele_mod_status
          t.date     :mouse_allele_mod_registered_date
          t.date     :rederivation_started_date
          t.date     :rederivation_complete_date
          t.date     :cre_excision_started_date
          t.date     :cre_excision_complete_date

          t.string   :phenotyping_status
          t.date     :phenotyping_registered_date
          t.date     :phenotyping_rederivation_started_date
          t.date     :phenotyping_rederivation_complete_date
          t.date     :phenotyping_experiments_started_date
          t.date     :phenotyping_started_date
          t.date     :phenotyping_complete_date
          t.date     :phenotype_attempt_aborted_date

          t.date     :created_at
    end

    add_index :intermediate_report_summary_by_gene, :catagory, name: 'irsg_catagory'
    add_index :intermediate_report_summary_by_gene, :approach, name: 'irsg_approach'
    add_index :intermediate_report_summary_by_gene, :allele_type, name: 'irsg_allele_type'

    add_index :intermediate_report_summary_by_gene, :mi_plan_id, name: 'irsg_mi_plans'
    add_index :intermediate_report_summary_by_gene, :mi_attempt_id, name: 'irsg_mi_attempts'
    add_index :intermediate_report_summary_by_gene, :mouse_allele_mod_id, name: 'irsg_mouse_allele_mods'
    add_index :intermediate_report_summary_by_gene, :phenotyping_production_id, name: 'irsg_phenotyping_productions'


    create_table :intermediate_report_summary_by_centre do |t|

          t.string   :catagory,     :null => false
          t.string   :approach,     :null => false
          t.string   :allele_type,  :null => false

          t.integer  :mi_plan_id
          t.integer  :mi_attempt_id
          t.integer  :modified_mouse_allele_mod_id
          t.integer  :mouse_allele_mod_id
          t.integer  :phenotyping_production_id

          t.string   :production_centre
          t.string   :gene
          t.string   :mgi_accession_id

          t.string   :mi_attempt_external_ref
          t.string   :mi_attempt_colony_name
          t.string   :mouse_allele_mod_colony_name
          t.string   :phenotyping_production_colony_name

          t.string   :mi_plan_status
          t.date     :gene_interest_date
          t.date     :assigned_date
          t.date     :assigned_es_cell_qc_in_progress_date
          t.date     :assigned_es_cell_qc_complete_date
          t.date     :aborted_es_cell_qc_failed_date

          t.string   :mi_attempt_status
          t.date     :micro_injection_aborted_date
          t.date     :micro_injection_in_progress_date
          t.date     :chimeras_obtained_date
          t.date     :founder_obtained_date
          t.date     :genotype_confirmed_date

          t.string   :mouse_allele_mod_status
          t.date     :mouse_allele_mod_registered_date
          t.date     :rederivation_started_date
          t.date     :rederivation_complete_date
          t.date     :cre_excision_started_date
          t.date     :cre_excision_complete_date

          t.string   :phenotyping_status
          t.date     :phenotyping_registered_date
          t.date     :phenotyping_rederivation_started_date
          t.date     :phenotyping_rederivation_complete_date
          t.date     :phenotyping_experiments_started_date
          t.date     :phenotyping_started_date
          t.date     :phenotyping_complete_date
          t.date     :phenotype_attempt_aborted_date

          t.date     :created_at
    end

    add_index :intermediate_report_summary_by_centre, :catagory, name: 'irscen_catagory'
    add_index :intermediate_report_summary_by_centre, :approach, name: 'irscen_approach'
    add_index :intermediate_report_summary_by_centre, :allele_type, name: 'irscen_allele_type'

    add_index :intermediate_report_summary_by_centre, :mi_plan_id, name: 'irscen_mi_plans'
    add_index :intermediate_report_summary_by_centre, :mi_attempt_id, name: 'irscen_mi_attempts'
    add_index :intermediate_report_summary_by_centre, :mouse_allele_mod_id, name: 'irscen_mouse_allele_mods'
    add_index :intermediate_report_summary_by_centre, :phenotyping_production_id, name: 'irscen_phenotyping_productions'

  end



  def self.down
    drop_table :intermediate_report_summary_by_gene
    drop_table :intermediate_report_summary_by_centre
  end
end
