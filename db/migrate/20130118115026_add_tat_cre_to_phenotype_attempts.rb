class AddTatCreToPhenotypeAttempts < ActiveRecord::Migration
  def self.up
    add_column :phenotype_attempts, :tat_cre, :boolean, :default => false
  end

  def self.down
    remove_column :phenotype_attempts, :tat_cre
  end
end
