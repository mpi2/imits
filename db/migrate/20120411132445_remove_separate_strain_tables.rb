class RemoveSeparateStrainTables < ActiveRecord::Migration
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
    remove_foreign_key :mi_attempts, :column => :blast_strain_id
    remove_foreign_key :mi_attempts, :column => :colony_background_strain_id
    remove_foreign_key :mi_attempts, :column => :test_cross_strain_id

    add_foreign_key :mi_attempts, :strains, :column => :blast_strain_id
    add_foreign_key :mi_attempts, :strains, :column => :colony_background_strain_id
    add_foreign_key :mi_attempts, :strains, :column => :test_cross_strain_id

    ID_TABLES.each do |table|
      drop_table table
    end
  end

  def self.down
    remove_foreign_key :mi_attempts, :column => :blast_strain_id
    remove_foreign_key :mi_attempts, :column => :colony_background_strain_id
    remove_foreign_key :mi_attempts, :column => :test_cross_strain_id

    ID_TABLES.each { |id_table| create_strain_type_table id_table }

    add_foreign_key :mi_attempts, :strain_blast_strains, :column => :blast_strain_id
    add_foreign_key :mi_attempts, :strain_colony_background_strains, :column => :colony_background_strain_id
    add_foreign_key :mi_attempts, :strain_test_cross_strains, :column => :test_cross_strain_id
  end
end
