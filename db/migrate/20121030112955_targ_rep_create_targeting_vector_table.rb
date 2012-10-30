class TargRepCreateTargetingVectorTable < ActiveRecord::Migration

  def self.up
    create_table "targ_rep_targeting_vectors" do |t|
      t.integer  "allele_id",           :null => false
      t.string   "name",                :null => false
      t.string   "ikmc_project_id"
      t.string   "intermediate_vector"
      t.boolean  "report_to_public",    :default => true, :null => false
      t.integer  "pipeline_id"

      t.timestamps
    end

    add_index "targ_rep_targeting_vectors", ["allele_id"], :name => "targeting_vectors_allele_id_fk"
    add_index "targ_rep_targeting_vectors", ["name"], :name => "index_targvec", :unique => true
    add_index "targ_rep_targeting_vectors", ["pipeline_id"], :name => "targeting_vectors_pipeline_id_fk"

  end

  def self.down
    drop_table "targ_rep_targeting_vectors"
  end

end
