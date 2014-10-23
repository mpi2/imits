class AddReconcileColsToDistributionCentres < ActiveRecord::Migration
  def self.up
  	add_column :mi_attempt_distribution_centres, :reconciled, :string, :null => false, :default => 'not checked'
    add_column :mi_attempt_distribution_centres, :reconciled_at, :datetime, :null => true

    add_column :phenotype_attempt_distribution_centres, :reconciled, :string, :null => false, :default => 'not checked'
    add_column :phenotype_attempt_distribution_centres, :reconciled_at, :datetime, :null => true

    add_column :genes, :komp_repo_geneid, :integer, :null => true
  end

  def self.down
    remove_column :mi_attempt_distribution_centres, :reconciled
    remove_column :mi_attempt_distribution_centres, :reconciled_at

    remove_column :phenotype_attempt_distribution_centres, :reconciled
    remove_column :phenotype_attempt_distribution_centres, :reconciled_at

    remove_column :genes, :komp_repo_geneid
  end
end