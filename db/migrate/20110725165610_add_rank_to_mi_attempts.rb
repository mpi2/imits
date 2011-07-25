class AddRankToMiAttempts < ActiveRecord::Migration
  def self.up
    add_column :mi_attempts, :rank, :integer
  end

  def self.down
    remove_column :mi_attempts, :rankls
  end
end
