class AddIgnoreToContactsTable < ActiveRecord::Migration
  def self.up
    add_column :contacts, :report_to_public, :boolean, :default => true

    ## Postgresql seems to have problems doing this in add_column
    Contact.reset_column_information
    Contact.update_all({:report_to_public => true})
  end

  def self.down
    remove_column :contacts, :report_to_public
  end
end
