class TargRepCreateEsCellQcConflictTable < ActiveRecord::Migration
  def self.up
    create_table "targ_rep_es_cell_qc_conflicts" do |t|
      t.integer  "es_cell_id"
      t.string   "qc_field",        :null => false
      t.string   "current_result",  :null => false
      t.string   "proposed_result", :null => false
      t.text     "comment"

      t.timestamps
    end

    add_index "targ_rep_es_cell_qc_conflicts", ["es_cell_id"], :name => "es_cell_qc_conflicts_es_cell_id_fk"
  end

  def self.down
    drop_table "targ_rep_es_cell_qc_conflicts"
  end
end
