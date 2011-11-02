class AddUserColumnIsContactable < ActiveRecord::Migration
  def self.up
    add_column :users, :is_contactable, :boolean, :default => false
  end

  def self.down
    remove_column :users, :is_contactable
  end
end
