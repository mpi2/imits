class CreateIntermediateReport < ActiveRecord::Migration
  def self.up
    create_table :intermediate_report do |t|
      t.string :consortium, :null => false, :size => 15
      t.string :sub_project, :null => false
      t.string :priority, :size => 10
      t.string :production_centre, :null => false, :limit => 100
      t.string :gene, :null => false, :limit => 75
      t.string :mgi_accession_id, :limit => 40
      t.string :overall_status, :limit => 50
      t.string :mi_plan_status, :limit => 50
      t.string :mi_attempt_status, :limit => 50
      t.string :phenotype_attempt_status, :limit => 50
      t.integer :ikmc_project_id
      t.string :mutation_sub_type, :limit => 100
      t.string :allele_symbol, :null => false, :limit => 75
      t.string :genetic_background, :null => false, :limit => 50
      t.date :assigned_date
      t.date :assigned_es_cell_qc_in_progress_date
      t.date :assigned_es_cell_qc_complete_date
      t.date :micro_injection_in_progress_date
      t.date :chimeras_obtained_date
      t.date :genotype_confirmed_date
      t.date :micro_injection_aborted_date
      t.date :phenotype_attempt_registered_date
      t.date :rederivation_started_date
      t.date :rederivation_complete_date
      t.date :cre_excision_started_date
      t.date :cre_excision_complete_date
      t.date :phenotyping_started_date
      t.date :phenotyping_complete_date
      t.date :phenotype_attempt_aborted_date
      t.integer :distinct_genotype_confirmed_es_cells
      t.integer :distinct_old_non_genotype_confirmed_es_cells
      t.integer :mi_plan_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :intermediate_report
  end
end
