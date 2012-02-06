class AddColonyNameToPhenotypeAttempts < ActiveRecord::Migration
  def self.up
    add_column :phenotype_attempts, :colony_name, :string, :limit => 125, :null => false
    add_index :phenotype_attempts, :colony_name, :unique => true
  end

  def self.down
    remove_column :phenotype_attempts, :colony_name
  end
end
