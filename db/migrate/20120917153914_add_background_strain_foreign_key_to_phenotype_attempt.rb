class AddBackgroundStrainForeignKeyToPhenotypeAttempt < ActiveRecord::Migration
  def self.up
    add_column :phenotype_attempts, :colony_background_strain_id, :integer
    add_foreign_key :phenotype_attempts, :strains, :column => :colony_background_strain_id
  end

  def self.down
    remove_foreign_key :phenotype_attempts, :column => :colony_background_strain_id
    remove_column :phenotype_attempts, :colony_background_strain_id
  end
end
