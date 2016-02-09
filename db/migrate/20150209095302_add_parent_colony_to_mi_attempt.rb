class AddParentColonyToMiAttempt < ActiveRecord::Migration

  def self.up
    add_column :mi_attempts, :parent_colony_id, :integer
  end

  def self.down
    remove_column :mi_attempts, :parent_colony_id
  end


end
