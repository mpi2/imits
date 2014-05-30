class ReOrganiseColumnsOfNewIntermediateReports < ActiveRecord::Migration

  def self.up

    create_table :new_intermediate_report_summary_by_mi_plan do |t|

      t.integer  :mi_plan_id,   :null => false

      t.string   :overall_status,           :limit => 50
      t.string   :mi_plan_status,           :limit => 50
      t.string   :mi_attempt_status,        :limit => 50
      t.string   :phenotype_attempt_status, :limit => 50

      t.string   :consortium,   :null => false
      t.string   :production_centre
      t.string   :sub_project
      t.string   :priority
      t.string   :gene
      t.string   :mgi_accession_id,         :limit => 40

      t.boolean  :is_bespoke_allele
      t.string   :ikmc_project_id
      t.string   :mutation_sub_type,        :limit => 100
      t.string   :allele_symbol
      t.string   :genetic_background

      t.string   :mi_attempt_colony_name
      t.string   :mouse_allele_mod_colony_name
      t.string   :production_colony_name

      t.date     :assigned_date
      t.date     :assigned_es_cell_qc_in_progress_date
      t.date     :assigned_es_cell_qc_complete_date
      t.date     :aborted_es_cell_qc_failed_date
      t.date     :micro_injection_in_progress_date
      t.date     :chimeras_obtained_date
      t.date     :genotype_confirmed_date
      t.date     :micro_injection_aborted_date
      t.date     :phenotype_attempt_registered_date
      t.date     :rederivation_started_date
      t.date     :rederivation_complete_date
      t.date     :cre_excision_started_date
      t.date     :cre_excision_complete_date
      t.date     :phenotyping_started_date
      t.date     :phenotyping_experiments_started_date
      t.date     :phenotyping_complete_date
      t.date     :phenotype_attempt_aborted_date
      t.string   :phenotyping_mi_attempt_consortium
      t.string   :phenotyping_mi_attempt_production_centre

      t.string  :tm1b_phenotype_attempt_status
      t.date    :tm1b_phenotype_attempt_registered_date
      t.date    :tm1b_rederivation_started_date
      t.date    :tm1b_rederivation_complete_date
      t.date    :tm1b_cre_excision_started_date
      t.date    :tm1b_cre_excision_complete_date
      t.date    :tm1b_phenotyping_started_date
      t.date    :tm1b_phenotyping_experiments_started_date
      t.date    :tm1b_phenotyping_complete_date
      t.date    :tm1b_phenotype_attempt_aborted_date
      t.string  :tm1b_colony_name
      t.string  :tm1b_phenotyping_production_colony_name
      t.string  :tm1b_phenotyping_mi_attempt_consortium
      t.string  :tm1b_phenotyping_mi_attempt_production_centre

      t.string  :tm1a_phenotype_attempt_status
      t.date    :tm1a_phenotype_attempt_registered_date
      t.date    :tm1a_rederivation_started_date
      t.date    :tm1a_rederivation_complete_date
      t.date    :tm1a_cre_excision_started_date
      t.date    :tm1a_cre_excision_complete_date
      t.date    :tm1a_phenotyping_started_date
      t.date    :tm1a_phenotyping_experiments_started_date
      t.date    :tm1a_phenotyping_complete_date
      t.date    :tm1a_phenotype_attempt_aborted_date
      t.string  :tm1a_colony_name
      t.string  :tm1a_phenotyping_production_colony_name
      t.string  :tm1a_phenotyping_mi_attempt_consortium
      t.string  :tm1a_phenotyping_mi_attempt_production_centre

      t.integer  :distinct_genotype_confirmed_es_cells
      t.integer  :distinct_old_genotype_confirmed_es_cells
      t.integer  :distinct_non_genotype_confirmed_es_cells
      t.integer  :distinct_old_non_genotype_confirmed_es_cells
      t.integer  :total_pipeline_efficiency_gene_count
      t.integer  :total_old_pipeline_efficiency_gene_count
      t.integer  :gc_pipeline_efficiency_gene_count
      t.integer  :gc_old_pipeline_efficiency_gene_count
      t.datetime :created_at
    end

    create_table :new_intermediate_report_summary_by_centre_and_consortia do |t|
      t.integer   :mi_plan_id,  :limit => 50
      t.integer   :mi_attempt_id,  :limit => 50
      t.integer   :mouse_allele_mod_id, :limit => 50
      t.integer   :phenotyping_production_id, :limit => 50

      t.string   :overall_status,           :limit => 50
      t.string   :mi_plan_status,           :limit => 50
      t.string   :mi_attempt_status,        :limit => 50
      t.string   :phenotype_attempt_status, :limit => 50

      t.string   :consortium,   :null => false
      t.string   :production_centre
      t.string   :gene,         :limit => 75,  :null => false
      t.string   :mgi_accession_id,         :limit => 40
      t.date     :gene_interest_date

      t.string   :mi_attempt_colony_name
      t.string   :mouse_allele_mod_colony_name
      t.string   :production_colony_name

      t.date     :assigned_date
      t.date     :assigned_es_cell_qc_in_progress_date
      t.date     :assigned_es_cell_qc_complete_date
      t.date     :aborted_es_cell_qc_failed_date

      t.date     :micro_injection_in_progress_date
      t.date     :chimeras_obtained_date
      t.date     :genotype_confirmed_date
      t.date     :micro_injection_aborted_date

      t.date     :phenotype_attempt_registered_date
      t.date     :rederivation_started_date
      t.date     :rederivation_complete_date
      t.date     :cre_excision_started_date
      t.date     :cre_excision_complete_date
      t.date     :phenotyping_started_date
      t.date     :phenotyping_experiments_started_date
      t.date     :phenotyping_complete_date
      t.date     :phenotype_attempt_aborted_date
      t.string   :phenotyping_mi_attempt_consortium
      t.string   :phenotyping_mi_attempt_production_centre

      t.string  :tm1b_phenotype_attempt_status
      t.date    :tm1b_phenotype_attempt_registered_date
      t.date    :tm1b_rederivation_started_date
      t.date    :tm1b_rederivation_complete_date
      t.date    :tm1b_cre_excision_started_date
      t.date    :tm1b_cre_excision_complete_date
      t.date    :tm1b_phenotyping_started_date
      t.date    :tm1b_phenotyping_experiments_started_date
      t.date    :tm1b_phenotyping_complete_date
      t.date    :tm1b_phenotype_attempt_aborted_date
      t.string  :tm1b_colony_name
      t.string  :tm1b_phenotyping_production_colony_name
      t.string  :tm1b_phenotyping_mi_attempt_consortium
      t.string  :tm1b_phenotyping_mi_attempt_production_centre

      t.string  :tm1a_phenotype_attempt_status
      t.date    :tm1a_phenotype_attempt_registered_date
      t.date    :tm1a_rederivation_started_date
      t.date    :tm1a_rederivation_complete_date
      t.date    :tm1a_cre_excision_started_date
      t.date    :tm1a_cre_excision_complete_date
      t.date    :tm1a_phenotyping_started_date
      t.date    :tm1a_phenotyping_experiments_started_date
      t.date    :tm1a_phenotyping_complete_date
      t.date    :tm1a_phenotype_attempt_aborted_date
      t.string  :tm1a_colony_name
      t.string  :tm1a_phenotyping_production_colony_name
      t.string  :tm1a_phenotyping_mi_attempt_consortium
      t.string  :tm1a_phenotyping_mi_attempt_production_centre

      t.integer :distinct_genotype_confirmed_es_cells
      t.integer :distinct_old_genotype_confirmed_es_cells
      t.integer :distinct_non_genotype_confirmed_es_cells
      t.integer :distinct_old_non_genotype_confirmed_es_cells
      t.integer :total_pipeline_efficiency_gene_count
      t.integer :total_old_pipeline_efficiency_gene_count
      t.integer :gc_pipeline_efficiency_gene_count
      t.integer :gc_old_pipeline_efficiency_gene_count

      t.datetime :created_at
    end

    create_table :new_intermediate_report_summary_by_consortia do |t|
      t.integer   :mi_plan_id,  :limit => 50
      t.integer   :mi_attempt_id,  :limit => 50
      t.integer   :mouse_allele_mod_id, :limit => 50
      t.integer   :phenotyping_production_id, :limit => 50

      t.string   :overall_status,           :limit => 50
      t.string   :mi_plan_status,           :limit => 50
      t.string   :mi_attempt_status,        :limit => 50
      t.string   :phenotype_attempt_status, :limit => 50

      t.string   :consortium,   :null => false
      t.string   :gene,         :limit => 75,  :null => false
      t.string   :mgi_accession_id,         :limit => 40
      t.date     :gene_interest_date

      t.string   :mi_attempt_colony_name
      t.string   :mouse_allele_mod_colony_name
      t.string   :production_colony_name

      t.date     :assigned_date
      t.date     :assigned_es_cell_qc_in_progress_date
      t.date     :assigned_es_cell_qc_complete_date
      t.date     :aborted_es_cell_qc_failed_date

      t.date     :micro_injection_in_progress_date
      t.date     :chimeras_obtained_date
      t.date     :genotype_confirmed_date
      t.date     :micro_injection_aborted_date

      t.date     :phenotype_attempt_registered_date
      t.date     :rederivation_started_date
      t.date     :rederivation_complete_date
      t.date     :cre_excision_started_date
      t.date     :cre_excision_complete_date
      t.date     :phenotyping_started_date
      t.date     :phenotyping_experiments_started_date
      t.date     :phenotyping_complete_date
      t.date     :phenotype_attempt_aborted_date
      t.string   :phenotyping_mi_attempt_consortium
      t.string   :phenotyping_mi_attempt_production_centre

      t.string    :tm1b_phenotype_attempt_status
      t.date    :tm1b_phenotype_attempt_registered_date
      t.date    :tm1b_rederivation_started_date
      t.date    :tm1b_rederivation_complete_date
      t.date    :tm1b_cre_excision_started_date
      t.date    :tm1b_cre_excision_complete_date
      t.date    :tm1b_phenotyping_started_date
      t.date    :tm1b_phenotyping_experiments_started_date
      t.date    :tm1b_phenotyping_complete_date
      t.date    :tm1b_phenotype_attempt_aborted_date
      t.string  :tm1b_colony_name
      t.string  :tm1b_phenotyping_production_colony_name
      t.string  :tm1b_phenotyping_mi_attempt_consortium
      t.string  :tm1b_phenotyping_mi_attempt_production_centre

      t.string  :tm1a_phenotype_attempt_status
      t.date    :tm1a_phenotype_attempt_registered_date
      t.date    :tm1a_rederivation_started_date
      t.date    :tm1a_rederivation_complete_date
      t.date    :tm1a_cre_excision_started_date
      t.date    :tm1a_cre_excision_complete_date
      t.date    :tm1a_phenotyping_started_date
      t.date    :tm1a_phenotyping_experiments_started_date
      t.date    :tm1a_phenotyping_complete_date
      t.date    :tm1a_phenotype_attempt_aborted_date
      t.string  :tm1a_colony_name
      t.string  :tm1a_phenotyping_production_colony_name
      t.string  :tm1a_phenotyping_mi_attempt_consortium
      t.string  :tm1a_phenotyping_mi_attempt_production_centre

      t.integer :distinct_genotype_confirmed_es_cells
      t.integer :distinct_old_genotype_confirmed_es_cells
      t.integer :distinct_non_genotype_confirmed_es_cells
      t.integer :distinct_old_non_genotype_confirmed_es_cells
      t.integer :total_pipeline_efficiency_gene_count
      t.integer :total_old_pipeline_efficiency_gene_count
      t.integer :gc_pipeline_efficiency_gene_count
      t.integer :gc_old_pipeline_efficiency_gene_count

      t.datetime :created_at
    end
  end



  def self.down

    drop_table :new_intermediate_report_summary_by_mi_plan
    drop_table :new_intermediate_report_summary_by_centre_and_consortia
    drop_table :new_intermediate_report_summary_by_consortia
  end
end
