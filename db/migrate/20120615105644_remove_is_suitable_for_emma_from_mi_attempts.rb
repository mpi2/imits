class RemoveIsSuitableForEmmaFromMiAttempts < ActiveRecord::Migration
  def self.up
    remove_column :mi_attempts, :is_suitable_for_emma
  end

  def self.down
    add_column :mi_attempts, :is_suitable_for_emma, :boolean, :null => false
  end
end
