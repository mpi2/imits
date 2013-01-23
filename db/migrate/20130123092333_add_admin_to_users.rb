class AddAdminToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :admin, :boolean, :default => false

    User.reset_column_information

    User.all.each do |u|
      if User::ADMIN_USERS.include?(u.email)
        u.update_attribute(:admin, true)
      end
    end
  end

  def self.down
    remove_column :users, :admin
  end
end
