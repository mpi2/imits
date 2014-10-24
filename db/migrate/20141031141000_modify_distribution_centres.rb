class ModifyDistributionCentres < ActiveRecord::Migration
  def self.up
    add_column :distribution_centres, :available, :boolean, :default => false
  end

  def self.down
    remove_column :distribution_centres, :available
  end

end