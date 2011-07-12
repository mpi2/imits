class CreateStrains < ActiveRecord::Migration
  def self.create_strain_type_table(name)
    create_table name, :id => false do |table|
      table.integer 'id', :null => false
      table.timestamps
    end
    add_index name, :id, :unique => true
    add_foreign_key name, :strains, :column => 'id'
  end

  ID_TABLES = [
    :strain_blast_strains,
    :strain_colony_background_strains,
    :strain_test_cross_strains
  ]

  def self.up
    create_table :strains do |table|
      table.string :name, :null => false, :limit => 50

      table.timestamps
    end
    add_index :strains, :name, :unique => true

    ID_TABLES.each { |id_table| create_strain_type_table id_table }
  end

  def self.down
    ID_TABLES.reverse.each { |id_table| drop_table id_table }
    drop_table :strains
  end
end
