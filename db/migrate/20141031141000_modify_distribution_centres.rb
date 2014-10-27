class ModifyDistributionCentres < ActiveRecord::Migration
  def self.up
    add_column :mi_attempt_distribution_centres, :available, :boolean, :default => false
    add_column :phenotype_attempt_distribution_centres, :available, :boolean, :default => false
  end

  def self.down
    remove_column :mi_attempt_distribution_centres, :available
    remove_column :phenotype_attempt_distribution_centres, :available
  end

end