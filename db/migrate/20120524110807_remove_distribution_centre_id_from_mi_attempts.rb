class RemoveDistributionCentreIdFromMiAttempts < ActiveRecord::Migration
  def self.up
    remove_column :mi_attempts, :distribution_centre_id
  end

  def self.down
    add_column :mi_attempts, :distribution_centre_id, :integer, :null => false
  end
end
