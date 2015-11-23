class ChangeGenbankFileDataStructure < ActiveRecord::Migration

  def self.up
    
    rename_table :targ_rep_genbank_files, :targ_rep_alleles_genbank_file_collections

    create_table :targ_rep_genbank_files do |t|
      t.text :file
      t.text :image
      t.text :simple_image

      t.timestamps
    end

    add_column :targ_rep_alleles_genbank_file_collections, :targeting_vector_genbank_file_id, :integer
    add_column :targ_rep_alleles_genbank_file_collections, :clone_genbank_file_id, :integer
    add_column :targ_rep_alleles_genbank_file_collections, :cre_excised_clone_genbank_file_id, :integer
    add_column :targ_rep_alleles_genbank_file_collections, :flp_excised_clone_genbank_file_id, :integer
    add_column :targ_rep_alleles_genbank_file_collections, :flp_cre_excised_clone_genbank_file_id, :integer


    add_column :colonies, :clone_genbank_file_id, :integer

    add_foreign_key :targ_rep_alleles_genbank_file_collections, :targ_rep_genbank_files, :column => :targeting_vector_genbank_file_id, :name => 'targeting_vector_genbank_file_fk'
    add_foreign_key :targ_rep_alleles_genbank_file_collections, :targ_rep_genbank_files, :column => :clone_genbank_file_id, :name => 'clone_genbank_file_fk'
    add_foreign_key :targ_rep_alleles_genbank_file_collections, :targ_rep_genbank_files, :column => :cre_excised_clone_genbank_file_id, :name => 'cre_excised_clone_genbank_file_fk'
    add_foreign_key :targ_rep_alleles_genbank_file_collections, :targ_rep_genbank_files, :column => :flp_excised_clone_genbank_file_id, :name => 'flp_excised_clone_genbank_file_fk'
    add_foreign_key :targ_rep_alleles_genbank_file_collections, :targ_rep_genbank_files, :column => :flp_cre_excised_clone_genbank_file_id, :name => 'flp_cre_excised_eclone_genbank_file_fk'
 
 #   The missing Promary Keys when dumping database without genbank files will issues.
 #   add_foreign_key :colonies, :targ_rep_genbank_files, :column => :clone_genbank_file_id, :name => 'clone_genbank_file_fk'

  end

  def self.down
    remove_foreign_key :targ_rep_alleles_genbank_file_collections, :name => :targeting_vector_genbank_file_fk
    remove_foreign_key :targ_rep_alleles_genbank_file_collections, :name => :clone_genbank_file_fk
    remove_foreign_key :targ_rep_alleles_genbank_file_collections, :name => :cre_excised_clone_genbank_file_fk
    remove_foreign_key :targ_rep_alleles_genbank_file_collections, :name => :flp_excised_clone_genbank_file_fk
    remove_foreign_key :targ_rep_alleles_genbank_file_collections, :name => :flp_cre_excised_eclone_genbank_file_fk

    remove_column :targ_rep_alleles_genbank_file_collections, :targeting_vector_genbank_file_id
    remove_column :targ_rep_alleles_genbank_file_collections, :clone_genbank_file_id,
    remove_column :targ_rep_alleles_genbank_file_collections, :cre_excised_clone_genbank_file_id
    remove_column :targ_rep_alleles_genbank_file_collections, :flp_excised_clone_genbank_file_id
    remove_column :targ_rep_alleles_genbank_file_collections, :flp_cre_excised_clone_genbank_file_id

 #   remove_foreign_key :colonies, :name => :clone_genbank_file_fk
    remove_column :colonies, :clone_genbank_file_id

    rename_table :targ_rep_alleles_genbank_file_collections, :targ_rep_genbank_files
    remove_table :targ_rep_genbank_files
  end
end
