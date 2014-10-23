class CreateNewColonyNameTable < ActiveRecord::Migration
  def self.up
    create_table :colonies do |t|
      t.string :name, :null => false
      t.integer :mi_attempt_id
    end

    add_foreign_key :colonies, :mi_attempts, :column => :mi_attempt_id, :name => 'colonies_mi_attempt_fk'
    add_index :colonies, [:name], :unique => true, :name => :colony_name_index
  end

  def self.down
    drop_table :colonies
  end

end
