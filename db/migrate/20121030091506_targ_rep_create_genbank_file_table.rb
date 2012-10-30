class TargRepCreateGenbankFileTable < ActiveRecord::Migration

  def self.up
    create_table "targ_rep_genbank_files" do |t|
      t.integer  "allele_id",        :null => false
      t.text     "escell_clone"
      t.text     "targeting_vector"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "targ_rep_genbank_files", ["allele_id"], :name => "genbank_files_allele_id_fk"
  end

  def self.down
    drop_table "targ_rep_genbank_files"
  end

end
