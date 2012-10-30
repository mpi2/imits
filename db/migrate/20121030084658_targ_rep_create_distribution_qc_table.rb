class TargRepCreateDistributionQcTable < ActiveRecord::Migration
  def self.up
    create_table "targ_rep_distribution_qcs" do |t|
      t.string   "five_prime_sr_pcr"
      t.string   "three_prime_sr_pcr"
      t.float    "karyotype_low"
      t.float    "karyotype_high"
      t.string   "copy_number"
      t.string   "five_prime_lr_pcr"
      t.string   "three_prime_lr_pcr"
      t.string   "thawing"
      t.string   "loa"
      t.string   "loxp"
      t.string   "lacz"
      t.string   "chr1"
      t.string   "chr8a"
      t.string   "chr8b"
      t.string   "chr11a"
      t.string   "chr11b"
      t.string   "chry"
      t.integer  "es_cell_id"
      t.integer  "es_cell_distribution_centre_id"
      
      t.timestamps

      add_index "targ_rep_distribution_qcs", ["es_cell_distribution_centre_id", "es_cell_id"], :name => "index_distribution_qcs_centre_es_cell", :unique => true
    end
  end

  def self.down
    drop_table "targ_rep_distribution_qcs"
  end
end
