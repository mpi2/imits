class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |table|
      table.database_authenticatable :null => false
      table.rememberable

      table.references :production_centre, :null => false

      table.timestamps
    end

    add_index :users, :email, :unique => true
  end

  def self.down
    drop_table :users
  end
end
