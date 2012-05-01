class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.timestamp :welcome_email_sent
      t.text :welcome_email_text
      t.timestamp :last_email_sent
      t.text :last_email_text
      t.integer :gene_id, :null => false
      t.integer :contact_id, :null => false
      t.timestamps
    end

    add_foreign_key :notifications, :genes
    add_foreign_key :notifications, :contacts
  end

  def self.down
    drop_table :notifications
  end
end
