class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.string :email, :null => false
      t.timestamps
    end
    add_index :contacts, :email, :unique => true

  end

  def self.down
    drop_table :contacts
  end
end
