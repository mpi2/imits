class CreateMiAttempts < ActiveRecord::Migration
  def self.up
    create_table :mi_attempts do |t|
      t.references :clone, :null => false
      t.date :mi_date

      t.timestamps
    end

    add_foreign_key :mi_attempts, :clones
  end

  def self.down
    drop_table :mi_attempts
  end
end
