class CreateNewPhenotypingTables < ActiveRecord::Migration

  def self.up

    create_table :mouse_allele_mods do |t|

      t.integer   :mi_plan_id, :null => false
      t.integer   :mi_attempt_id, :null => false
      t.integer   :status_id, :null => false
      t.boolean   :rederivation_started, :default => false, :null => false
      t.boolean   :rederivation_complete, :default => false, :null => false
      t.integer   :number_of_cre_matings_started, :default => 0, :null => false
      t.integer   :number_of_cre_matings_successful, :default => 0, :null => false
      t.boolean   :no_modification_required, :default => false
      t.boolean   :cre_excision, :default => true, :null => false
      t.boolean   :tat_cre, :default => false
      t.string    :mouse_allele_type, :limit => 3
      t.string    :allele_category
      t.integer   :deleter_strain_id
      t.integer   :colony_background_strain_id
      t.string    :colony_name, :limit => 125, :null => false
      t.boolean   :is_active, :default => true, :null => false
      t.boolean   :report_to_public, :default => true, :null => false
      t.integer   :phenotype_attempt_id

      t.timestamps
    end

    create_table :mouse_allele_mod_statuses do |t|
      t.string :name, :null => false, :limit => 50
      t.integer :order_by, :null => false
      t.string :code, :null => false, :limit => 4
    end

    create_table :mouse_allele_mod_status_stamps do |table|
      table.integer :mouse_allele_mod_id, :null => false
      table.integer :status_id, :null => false
      table.timestamps
    end


    create_table :phenotyping_productions do |t|

      t.integer  :mi_plan_id, :null => false
      t.integer  :mouse_allele_mod_id, :null => false
      t.integer  :status_id, :null => false
      t.string   :colony_name, :limit => 125, :null => false
      t.date     :phenotyping_experiments_started
      t.boolean  :phenotyping_started, :default => false, :null => false
      t.boolean  :phenotyping_complete, :default => false, :null => false
      t.boolean  :is_active, :default => true, :null => false
      t.boolean  :report_to_public, :default => true, :null => false
      t.integer  :phenotype_attempt_id
      t.timestamps
    end

    create_table :phenotyping_production_statuses do |t|
      t.string :name, :null => false, :limit => 50
      t.integer :order_by, :null => false
      t.string :code, :null => false, :limit => 4
    end


    create_table :phenotyping_production_status_stamps do |table|
      table.integer :phenotyping_production_id, :null => false
      table.integer :status_id, :null => false

      table.timestamps
    end

    add_column :phenotype_attempt_distribution_centres, :mouse_allele_mod_id, :integer

    execute <<-SQL
      ALTER TABLE phenotype_attempt_distribution_centres
        ADD CONSTRAINT fk_mouse_allele_mod_distribution_centres
        FOREIGN KEY (mouse_allele_mod_id)
        REFERENCES mouse_allele_mods(id)
    SQL

    add_foreign_key :mouse_allele_mods, :mi_plans, :column => :mi_plan_id
    add_foreign_key :mouse_allele_mods, :mi_attempts, :column => :mi_attempt_id
    add_foreign_key :mouse_allele_mods, :mouse_allele_mod_statuses, :column => :status_id
    add_foreign_key :mouse_allele_mods, :strains, :column => :deleter_strain_id
    add_foreign_key :mouse_allele_mods, :strains, :column => :colony_background_strain_id
    add_foreign_key :mouse_allele_mods, :phenotype_attempts, :column => :phenotype_attempt_id

    add_foreign_key :mouse_allele_mod_status_stamps, :mouse_allele_mod_statuses, :column => :status_id

    execute <<-SQL
      ALTER TABLE mouse_allele_mod_status_stamps
        ADD CONSTRAINT fk_mouse_allele_mods
        FOREIGN KEY (mouse_allele_mod_id)
        REFERENCES mouse_allele_mods(id)
    SQL

    add_foreign_key :phenotyping_productions, :mi_plans, :column => :mi_plan_id
    add_foreign_key :phenotyping_productions, :mouse_allele_mods, :column => :mouse_allele_mod_id
    add_foreign_key :phenotyping_productions, :phenotyping_production_statuses, :column => :status_id
    add_foreign_key :phenotyping_productions, :phenotype_attempts, :column => :phenotype_attempt_id

    add_foreign_key :phenotyping_production_status_stamps, :phenotyping_production_statuses, :column => :status_id
    execute <<-SQL
      ALTER TABLE phenotyping_production_status_stamps
        ADD CONSTRAINT fk_phenotyping_productions
        FOREIGN KEY (phenotyping_production_id)
        REFERENCES phenotyping_productions(id)
    SQL

    execute <<-SQL
      INSERT INTO mouse_allele_mod_statuses (name, order_by, code) VALUES
      ('Phenotype Attempt Registered', 420, 'par'),
      ('Mouse Allele Modification Registered', 410, 'mpr'),
      ('Rederivation Started', 430, 'res'),
      ('Rederivation Complete', 440, 'rec'),
      ('Cre Excision Started', 450, 'ces'),
      ('Cre Excision Complete', 460, 'cec'),
      ('Mouse Allele Modification Aborted', 401, 'abt')
    SQL

    execute <<-SQL
      INSERT INTO phenotyping_production_statuses (name, order_by, code) VALUES
      ('Phenotype Attempt Registered', 420, 'mpr'),
      ('Phenotyping Production Registered', 411, 'ppr'),
      ('Phenotyping Started', 530, 'pds'),
      ('Phenotyping Complete', 540, 'pdc'),
      ('Phenotype Production Aborted', 402, 'abt')
    SQL
  end



  def self.down
    execute <<-SQL
          ALTER TABLE phenotype_attempt_distribution_centres
            DROP CONSTRAINT fk_mouse_allele_mod_distribution_centres
        SQL
    remove_column :phenotype_attempt_distribution_centres, :mouse_allele_mod_id

    drop_table :phenotyping_production_status_stamps
    drop_table :phenotyping_productions
    drop_table :phenotyping_production_statuses

    drop_table :mouse_allele_mod_status_stamps
    drop_table :mouse_allele_mods
    drop_table :mouse_allele_mod_statuses


  end
end
