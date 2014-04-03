class AlterTargRepAlleleAssemblyDefault < ActiveRecord::Migration

  def self.up
    change_column :targ_rep_alleles, :assembly, :string, :default => 'GRCm38'
    add_column :targ_rep_alleles, :sequence, :text
    add_column :targ_rep_genbank_files, :allele_genbank_file, :text

    create_table :targ_rep_sequence_annotation do |t|
      t.integer :coordinate_start
      t.integer :coordinate_start
      t.string :expected_sequence
      t.string :actual_sequence
      t.integer :allele_id
    end
  end

  def self.down
    change_column :targ_rep_alleles, :assembly, :string, :default => 'NCBIM37'
    remove_column :targ_rep_alleles, :sequence
    remove_column :targ_rep_genbank_files, :allele_genbank_file
    drop_table :targ_rep_sequence_annotation
  end
end
