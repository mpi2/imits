class AddConsortiumToTrackingGoals < ActiveRecord::Migration
  def self.up
    add_column :tracking_goals, :consortium_id, :integer
  end

  def self.down
    remove_column :tracking_goals, :consortium_id
  end
end
