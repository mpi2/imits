class AddLegacyIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :legacy_id, :integer
  end

  def self.down
    remove_column :users, :legacy_id
  end
end
