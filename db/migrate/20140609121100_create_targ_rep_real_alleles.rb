class CreateTargRepRealAlleles < ActiveRecord::Migration
  def self.up
    create_table :targ_rep_real_alleles do |t|
      t.integer :gene_id, :null => false
      t.string :allele_name, :null => false, :limit => 20
      t.string :allele_type, :null => false, :limit => 10
    end

    add_foreign_key :targ_rep_real_alleles, :genes, :column => :gene_id

    add_index :targ_rep_real_alleles, [ :gene_id, :allele_name ], :unique => true, :name => :real_allele_logical_key
  end

  def self.down
    drop_table :targ_rep_real_alleles
  end
end