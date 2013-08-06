class AddContactFieldsToMiPlan < ActiveRecord::Migration
  def self.up
    add_column :centres, :contact_name, :string, :limit => 100
    add_column :centres, :contact_email, :string, :limit => 100
  end

  def self.down
    remove_column :centres, :contact_name
    remove_column :centres, :contact_email
  end
end
