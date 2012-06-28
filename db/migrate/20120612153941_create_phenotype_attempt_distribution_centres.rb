class CreatePhenotypeAttemptDistributionCentres < ActiveRecord::Migration
  def self.up
    create_table :phenotype_attempt_distribution_centres do |table|
      table.date :start_date
      table.date :end_date
      table.integer :phenotype_attempt_id, :null => false
      table.integer :deposited_material_id, :null => false
      table.integer :centre_id, :null => false
      table.boolean :is_distributed_by_emma, :null => false, :default => false

      table.timestamps
    end

    add_foreign_key :phenotype_attempt_distribution_centres, :phenotype_attempts
    add_foreign_key :phenotype_attempt_distribution_centres, :deposited_materials
    add_foreign_key :phenotype_attempt_distribution_centres, :centres
  end

  def self.down
    drop_table :phenotype_attempt_distribution_centres
  end
end
