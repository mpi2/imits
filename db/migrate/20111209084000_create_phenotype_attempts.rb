class CreatePhenotypeAttempts < ActiveRecord::Migration
  def self.up
    create_table :phenotype_attempts do |t|
      t.integer :mi_attempt_id, :null => false
      t.integer :status_id, :null => false
      t.boolean :is_active, :null => false, :default => true
      t.boolean :rederivation_started, :null => false, :default => false
      t.boolean :rederivation_complete, :null => false, :default => false
      t.integer :number_of_cre_matings_started, :null => false, :default => 0
      t.integer :number_of_cre_matings_successful, :null => false, :default => 0

      t.timestamps
    end

    add_foreign_key :phenotype_attempts, :phenotype_attempt_statuses, :column => :status_id
  end

  def self.down
    drop_table :phenotype_attempts
  end
end
