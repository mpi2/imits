class CreateGenotypePrimer < ActiveRecord::Migration
  def self.up
    # create real alleles table
    create_table :targ_rep_genotype_primers do |t|
      t.string :sequence, :null => false
      t.string :name
      t.integer :genomic_start_coordinate
      t.integer :genomic_end_coordinate
      t.integer :mutagenesis_factor_id
      t.integer :allele_id
    end

    add_foreign_key :targ_rep_genotype_primers, :mutagenesis_factors, :column => :mutagenesis_factor_id
    add_foreign_key :targ_rep_genotype_primers, :targ_rep_alleles, :column => :allele_id
  end

  def self.down
    # drop targ rep genotype primers table
    drop_table :targ_rep_genotype_primers
  end
end