class CreateCrispr < ActiveRecord::Migration

  def self.up

  create_table :targ_rep_crisprs do |t|
      t.string   :name,      :null => false
      t.integer  :gene_id,   :null => false
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :targ_rep_crisprs
  end
end
