class CreateCrispr < ActiveRecord::Migration

  def self.up

  create_table :targ_rep_crisprs do |t|
      t.integer  :mutagenesis_factor_id, :null => false
      t.string   :sequence, :null => false
      t.string   :chr
      t.integer  :start
      t.integer  :end
      t.datetime :created_at
    end

    create_table :mutagenesis_factors do |t|
      t.integer :vector_id, :null => true
    end

    add_column :mi_attempts, :mutagenesis_factor_id, :integer
    change_column :mi_attempts, :es_cell_id, :integer, :null => true
  end

  def self.down
    drop_table :targ_rep_crisprs
    drop_table :mutagenesis_factors

    change_column :mi_attempts, :es_cell_id, :integer, :null => false
    remove_column :mi_attempts, :mutagenesis_factor_id
  end
end
