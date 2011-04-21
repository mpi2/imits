class CreateStrains < ActiveRecord::Migration
  def self.create_strain_type_table(name)
    create_table name, :id => false do |table|
      table.integer 'id', :null => false
      table.timestamps
    end
    add_index name, :id, :unique => true
    add_foreign_key name, :strains, :column => 'id'
  end

  def self.up
    create_table :strains do |table|
      table.text :name, :null => false

      table.timestamps
    end
    add_index :strains, :name, :unique => true

    create_strain_type_table(:blast_strains)
    create_strain_type_table(:colony_background_strains)
    create_strain_type_table(:test_cross_strains)
  end

  def self.down
    drop_table :test_cross_strains
    drop_table :colony_background_strains
    drop_table :blast_strains
    drop_table :strains
  end
end
