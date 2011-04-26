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

    create_strain_type_table(:strains_blast_strain_ids)
    create_strain_type_table(:strains_colony_background_strain_ids)
    create_strain_type_table(:strains_test_cross_strain_ids)
  end

  def self.down
    drop_table :strains_test_cross_strain_ids
    drop_table :strains_colony_background_strain_ids
    drop_table :strains_blast_strain_ids
    drop_table :strains
  end
end
