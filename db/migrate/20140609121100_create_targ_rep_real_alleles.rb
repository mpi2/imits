class CreateTargRepRealAlleles < ActiveRecord::Migration
  def self.up
    # create real alleles table
    create_table :targ_rep_real_alleles do |t|
      t.integer :gene_id, :null => false
      t.string :allele_name, :null => false, :limit => 20
      t.string :allele_type, :null => true, :limit => 10
    end

    add_foreign_key :targ_rep_real_alleles, :genes, :column => :gene_id

    add_index :targ_rep_real_alleles, [ :gene_id, :allele_name ], :unique => true, :name => :real_allele_logical_key

    # add columns and foreign keys to mi_attempts
    add_column :mi_attempts, :allele_id, :integer, :null => true
    add_column :mi_attempts, :real_allele_id, :integer, :null => true

    add_foreign_key :mi_attempts, :targ_rep_alleles, :column => :allele_id, :name => 'mi_attempts_targ_rep_allele_id_fk'
    add_foreign_key :mi_attempts, :targ_rep_real_alleles, :column => :real_allele_id, :name => 'mi_attempts_targ_rep_real_allele_id_fk'

    # add columns and foreign keys to phenotype_attempts
    add_column :phenotype_attempts, :allele_id, :integer, :null => true
    add_column :phenotype_attempts, :real_allele_id, :integer, :null => true

    add_foreign_key :phenotype_attempts, :targ_rep_alleles, :column => :allele_id, :name => 'phenotype_attempts_targ_rep_allele_id_fk'
    add_foreign_key :phenotype_attempts, :targ_rep_real_alleles, :column => :real_allele_id, :name => 'phenotype_attempts_targ_rep_real_allele_id_fk'

    # add columns and foreign keys to mouse_allele_mods
    add_column :mouse_allele_mods, :allele_id, :integer, :null => true
    add_column :mouse_allele_mods, :real_allele_id, :integer, :null => true

    add_foreign_key :mouse_allele_mods, :targ_rep_alleles, :column => :allele_id, :name => 'mouse_allele_mods_targ_rep_allele_id_fk'
    add_foreign_key :mouse_allele_mods, :targ_rep_real_alleles, :column => :real_allele_id, :name => 'mouse_allele_mods_targ_rep_real_allele_id_fk'

    # add columns and foreign keys to targ_rep_es_cells
    add_column :targ_rep_es_cells, :real_allele_id, :integer, :null => true

    add_foreign_key :targ_rep_es_cells, :targ_rep_real_alleles, :column => :real_allele_id, :name => 'targ_rep_es_cells_targ_rep_real_allele_id_fk'

    # add columns and foreign keys to targ_rep_targeting_vectors
    add_column :targ_rep_targeting_vectors, :real_allele_id, :integer, :null => true

    add_foreign_key :targ_rep_targeting_vectors, :targ_rep_real_alleles, :column => :real_allele_id, :name => 'targ_rep_targeting_vectors_targ_rep_real_allele_id_fk'

  end

  def self.down
    # remove columns and foreign keys to mi_attempts
    remove_foreign_key :mi_attempts, :name => 'mi_attempts_targ_rep_allele_id_fk'
    remove_foreign_key :mi_attempts, :name => 'mi_attempts_targ_rep_real_allele_id_fk'

    remove_column :mi_attempts, :allele_id
    remove_column :mi_attempts, :real_allele_id

    # remove columns and foreign keys to phenotype_attempts
    remove_foreign_key :phenotype_attempts, :name => 'phenotype_attempts_targ_rep_allele_id_fk'
    remove_foreign_key :phenotype_attempts, :name => 'phenotype_attempts_targ_rep_real_allele_id_fk'

    remove_column :phenotype_attempts, :allele_id
    remove_column :phenotype_attempts, :real_allele_id

    # remove columns and foreign keys to mouse_allele_mods
    remove_foreign_key :mouse_allele_mods, :name => 'mouse_allele_mods_targ_rep_allele_id_fk'
    remove_foreign_key :mouse_allele_mods, :name => 'mouse_allele_mods_targ_rep_real_allele_id_fk'

    remove_column :mouse_allele_mods, :allele_id
    remove_column :mouse_allele_mods, :real_allele_id

    # remove columns and foreign keys to targ_rep_es_cells
    remove_foreign_key :targ_rep_es_cells, :name => 'targ_rep_es_cells_targ_rep_real_allele_id_fk'

    remove_column :targ_rep_es_cells, :real_allele_id

    # remove columns and foreign keys to targ_rep_targeting_vectors
    remove_foreign_key :targ_rep_targeting_vectors, :name => 'targ_rep_targeting_vectors_targ_rep_real_allele_id_fk'

    remove_column :targ_rep_targeting_vectors, :real_allele_id

    # drop real alleles table
    drop_table :targ_rep_real_alleles
  end
end