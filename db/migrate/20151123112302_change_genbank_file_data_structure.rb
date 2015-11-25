class ChangeGenbankFileDataStructure < ActiveRecord::Migration

  def self.up
    
    rename_table :targ_rep_genbank_files, :targ_rep_alleles_genbank_file_collections

    create_table :targ_rep_genbank_files do |t|
      t.integer :genbank_file_collection_id
      t.integer :colony_id
      t.string :sequence_type
      t.text :file
      t.binary :image
      t.binary :simple_image
      t.timestamps
    end

  end

  def self.down
    drop_table :targ_rep_genbank_files
    rename_table :targ_rep_alleles_genbank_file_collections, :targ_rep_genbank_files
  end
end
