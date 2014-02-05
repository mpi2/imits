class CreateCrispr < ActiveRecord::Migration

  def self.up

  create_table :targ_rep_crisprs do |t|
      t.integer  :mutagensis_factor_id, :null => false
      t.string   :sequence, :null => false
      t.integer  :start
      t.integer  :end
      t.integer  :gene_id,   :null => false
      t.datetime :created_at
    end

    create_table :mutagenesis_factors do |t|
      t.integer :vector_id, :null => true
      t.string :crispr_method, :null => false
    end
  end

  def self.down
    drop_table :targ_rep_crisprs
    drop_table :mutagenesis_factors
  end
end
