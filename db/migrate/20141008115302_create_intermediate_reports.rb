class CreateIntermediateReports < ActiveRecord::Migration

  def self.up

    create_table :intermediate_report_summary_by_mi_plan do |t|

          t.string   :catagory,     :null => false
          t.string   :approach,     :null => false
          t.string   :allele_type,  :null => false

          t.integer  :mi_plan_id
          t.integer  :mi_attempt_id
          t.integer  :modified_mouse_allele_mod_id
          t.integer  :mouse_allele_mod_id
          t.integer  :phenotyping_production_id

          t.string   :consortium
          t.string   :production_centre
          t.string   :sub_project
          t.string   :priority

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

          t.integer  :mi_aborted_count
          t.date     :mi_aborted_max_date
          t.integer  :allele_mod_aborted_count
          t.date     :allele_mod_aborted_max_date

          t.date     :created_at
    end

    add_index :intermediate_report_summary_by_mi_plan, :catagory, name: 'irsmp_catagory'
    add_index :intermediate_report_summary_by_mi_plan, :approach, name: 'irsmp_approach'
    add_index :intermediate_report_summary_by_mi_plan, :allele_type, name: 'irsmp_allele_type'

    add_index :intermediate_report_summary_by_mi_plan, :mi_plan_id, name: 'irsmp_mi_plans'
    add_index :intermediate_report_summary_by_mi_plan, :mi_attempt_id, name: 'irsmp_mi_attempts'
    add_index :intermediate_report_summary_by_mi_plan, :mouse_allele_mod_id, name: 'irsmp_mouse_allele_mods'
    add_index :intermediate_report_summary_by_mi_plan, :phenotyping_production_id, name: 'irsmp_phenotyping_productions'

    create_table :intermediate_report_summary_by_consortia do |t|

          t.string   :catagory,     :null => false
          t.string   :approach,     :null => false
          t.string   :allele_type,  :null => false

          t.integer  :mi_plan_id
          t.integer  :mi_attempt_id
          t.integer  :modified_mouse_allele_mod_id
          t.integer  :mouse_allele_mod_id
          t.integer  :phenotyping_production_id

          t.string   :consortium
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

    add_index :intermediate_report_summary_by_consortia, :catagory, name: 'irsc_catagory'
    add_index :intermediate_report_summary_by_consortia, :approach, name: 'irsc_approach'
    add_index :intermediate_report_summary_by_consortia, :allele_type, name: 'irsc_allele_type'

    add_index :intermediate_report_summary_by_consortia, :mi_plan_id, name: 'irsc_mi_plans'
    add_index :intermediate_report_summary_by_consortia, :mi_attempt_id, name: 'irsc_mi_attempts'
    add_index :intermediate_report_summary_by_consortia, :mouse_allele_mod_id, name: 'irsc_mouse_allele_mods'
    add_index :intermediate_report_summary_by_consortia, :phenotyping_production_id, name: 'irsc_phenotyping_productions'

    create_table :intermediate_report_summary_by_centre_and_consortia do |t|

          t.string   :catagory,     :null => false
          t.string   :approach,     :null => false
          t.string   :allele_type,  :null => false

          t.integer  :mi_plan_id
          t.integer  :mi_attempt_id
          t.integer  :modified_mouse_allele_mod_id
          t.integer  :mouse_allele_mod_id
          t.integer  :phenotyping_production_id

          t.string   :consortium
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

    add_index :intermediate_report_summary_by_centre_and_consortia, :catagory, name: 'irscc_catagory'
    add_index :intermediate_report_summary_by_centre_and_consortia, :approach, name: 'irscc_approach'
    add_index :intermediate_report_summary_by_centre_and_consortia, :allele_type, name: 'irscc_allele_type'

    add_index :intermediate_report_summary_by_centre_and_consortia, :mi_plan_id, name: 'irscc_mi_plans'
    add_index :intermediate_report_summary_by_centre_and_consortia, :mi_attempt_id, name: 'irscc_mi_attempts'
    add_index :intermediate_report_summary_by_centre_and_consortia, :mouse_allele_mod_id, name: 'irscc_mouse_allele_mods'
    add_index :intermediate_report_summary_by_centre_and_consortia, :phenotyping_production_id, name: 'irscc_phenotyping_productions'

    drop_table :new_intermediate_report_summary_by_centre
    drop_table :new_intermediate_report_summary_by_centre_and_consortia
    drop_table :new_intermediate_report_summary_by_consortia
    drop_table :new_intermediate_report_summary_by_gene
    drop_table :new_intermediate_report_summary_by_mi_plan
  end



  def self.down

#    remove_index :intermediate_report_summary_by_mi_plan, :catagory
#    remove_index :intermediate_report_summary_by_mi_plan, :approach
#    remove_index :intermediate_report_summary_by_mi_plan, :allele_type

#    remove_index :intermediate_report_summary_by_consortia, :catagory
#    remove_index :intermediate_report_summary_by_consortia, :approach
#    remove_index :intermediate_report_summary_by_consortia, :allele_type

#    remove_index :intermediate_report_summary_by_centre_and_consortia, :catagory
#    remove_index :intermediate_report_summary_by_centre_and_consortia, :approach
#    remove_index :intermediate_report_summary_by_centre_and_consortia, :allele_type

    drop_table :intermediate_report_summary_by_mi_plan
    drop_table :intermediate_report_summary_by_consortia
    drop_table :intermediate_report_summary_by_centre_and_consortia
  end
end
