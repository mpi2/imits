class AddReconcileColsToDistributionCentres < ActiveRecord::Migration
  def self.up
  	add_column :mi_attempt_distribution_centres, :reconciled, :string, :null => false, :default => 'not checked'
    add_column :phenotype_attempt_distribution_centres, :reconciled, :string, :null => false, :default => 'not checked'
  end

  def self.down
    remove_column :mi_attempt_distribution_centres, :reconciled
    remove_column :phenotype_attempt_distribution_centres, :reconciled
  end
end