class AddDistribtionNetworkToPhenotypeAttemptDistributionCentre < ActiveRecord::Migration
  def self.up
    add_column :phenotype_attempt_distribution_centres, :distribution_network, :string
  end

  def self.down
    remove_column :phenotype_attempt_distribution_centres, :distribution_network
  end
end
