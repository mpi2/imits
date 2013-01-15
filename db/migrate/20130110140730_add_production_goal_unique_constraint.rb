class AddProductionGoalUniqueConstraint < ActiveRecord::Migration
  def self.up
    add_index :production_goals, [:consortium_id, :year, :month], :unique => true
  end

  def self.down
    remove_index :production_goals, [:consortium_id, :year, :month]
  end
end
