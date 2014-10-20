class CreateAlleleSequenceAnotation < ActiveRecord::Migration
  def self.up
    create_table :targ_rep_allele_sequence_annotations do |t|
      t.string :mutation_type
      t.string :expected
      t.string :actual
      t.text :comment
      t.integer :oligos_start_coordinate
      t.integer :oligos_end_coordinate
      t.integer :mutation_length
      t.integer :genomic_start_coordinate
      t.integer :genomic_end_coordinate
      t.integer :allele_id
    end

    add_foreign_key :targ_rep_allele_sequence_annotations, :targ_rep_alleles, :column => :allele_id
  end

  def self.down
    drop_table :targ_rep_allele_sequence_annotations
  end
end