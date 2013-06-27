class CreateNewGeneIntermediateReport < ActiveRecord::Migration

  def self.up

  create_table :new_gene_intermediate_report do |t|
      t.string   :gene,         :limit => 75,  :null => false
      t.string   :consortium,   :null => false
      t.string   :production_centre
      t.string   :mgi_accession_id,         :limit => 40

      t.string   :overall_status,           :limit => 50
      t.string   :mi_plan_status,           :limit => 50
      t.string   :mi_attempt_status,        :limit => 50
      t.string   :phenotype_attempt_status, :limit => 50

      t.date     :assigned_date
      t.date     :assigned_es_cell_qc_in_progress_date
      t.date     :assigned_es_cell_qc_complete_date
      t.date     :aborted_es_cell_qc_failed_date

      t.string   :ikmc_project_id
      t.string   :mutation_sub_type,        :limit => 100
      t.string   :allele_symbol
      t.string   :genetic_background

      t.string   :mi_attempt_colony_name
      t.string   :mi_attempt_consortium
      t.string   :mi_attempt_production_centre
      t.string   :phenotype_attempt_colony_name

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
      t.date     :phenotyping_complete_date
      t.date     :phenotype_attempt_aborted_date

      t.integer  :distinct_genotype_confirmed_es_cells
      t.integer  :distinct_old_genotype_confirmed_es_cells
      t.integer  :distinct_non_genotype_confirmed_es_cells
      t.integer  :distinct_old_non_genotype_confirmed_es_cells
      t.integer  :total_pipeline_efficiency_gene_count
      t.integer  :total_old_pipeline_efficiency_gene_count
      t.integer  :gc_pipeline_efficiency_gene_count
      t.integer  :gc_old_pipeline_efficiency_gene_count

      t.integer   :most_advanced_mi_plan_id_by_consortia,  :limit => 50

      t.datetime :created_at
    end
  end

  def self.down
    drop_table :new_gene_intermediate_report
  end
end
