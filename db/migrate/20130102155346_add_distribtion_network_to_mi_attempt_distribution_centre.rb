class AddDistribtionNetworkToMiAttemptDistributionCentre < ActiveRecord::Migration
  def self.up
    add_column :mi_attempt_distribution_centres, :distribution_network, :string
  end

  def self.down
    remove_column :mi_attempt_distribution_centres, :distribution_network
  end
end
