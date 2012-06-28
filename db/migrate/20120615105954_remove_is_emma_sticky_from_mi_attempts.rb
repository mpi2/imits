class RemoveIsEmmaStickyFromMiAttempts < ActiveRecord::Migration
  def self.up
    remove_column :mi_attempts, :is_emma_sticky
  end

  def self.down
    add_column :mi_attempts, :is_emma_sticky, :boolean, :null => false
  end
end
