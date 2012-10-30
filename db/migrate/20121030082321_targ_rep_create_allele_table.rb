class TargRepCreateAlleleTable < ActiveRecord::Migration
  def self.up

    create_table "targ_rep_alleles" do |t|
      t.integer  "gene_id"
      t.string   "assembly",            :limit => 50,  :default => "NCBIM37", :null => false
      t.string   "chromosome",          :limit => 2,                          :null => false
      t.string   "strand",              :limit => 1,                          :null => false
      t.integer  "homology_arm_start",                                        :null => false
      t.integer  "homology_arm_end",                                          :null => false
      t.integer  "loxp_start"
      t.integer  "loxp_end"
      t.integer  "cassette_start"
      t.integer  "cassette_end"
      t.string   "cassette",    :limit => 100
      t.string   "backbone",    :limit => 100
      t.string   "subtype_description"
      t.string   "floxed_start_exon"
      t.string   "floxed_end_exon"
      t.integer  "project_design_id"
      t.string   "reporter"
      t.integer  "mutation_method_id"
      t.integer  "mutation_type_id"
      t.integer  "mutation_subtype_id"
      t.string   "reporter"
      t.string   "cassette_type",       :limit => 50

      t.timestamps
    end
      
  end

  def self.down
    drop_table "targ_rep_alleles"
  end
end
