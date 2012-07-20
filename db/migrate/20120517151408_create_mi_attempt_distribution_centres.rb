class CreateMiAttemptDistributionCentres < ActiveRecord::Migration
  def self.up
    create_table :mi_attempt_distribution_centres do |table|
      table.date :start_date
      table.date :end_date
      table.integer :mi_attempt_id, :null => false
      table.integer :deposited_material_id, :null => false
      table.integer :centre_id, :null => false
      table.boolean :is_distributed_by_emma, :null => false, :default => false

      table.timestamps
    end

    add_foreign_key :mi_attempt_distribution_centres, :mi_attempts
    add_foreign_key :mi_attempt_distribution_centres, :deposited_materials
    add_foreign_key :mi_attempt_distribution_centres, :centres
  end

  def self.down
    drop_table :mi_attempt_distribution_centres
  end
end
