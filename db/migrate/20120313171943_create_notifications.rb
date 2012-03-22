class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.timestamp :welcome_email_sent
      t.timestamp :last_email_sent
      t.integer :gene_id
      t.integer :contact_id
      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
