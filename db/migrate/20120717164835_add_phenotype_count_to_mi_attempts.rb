class AddPhenotypeCountToMiAttempts < ActiveRecord::Migration

  def self.up
    add_column :mi_attempts, :phenotype_count, :integer
  end

  def self.down
    remove_column :mi_attempts, :phenotype_count
  end
end
