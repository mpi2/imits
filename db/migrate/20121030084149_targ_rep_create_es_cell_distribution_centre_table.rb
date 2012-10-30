class TargRepCreateEsCellDistributionCentreTable < ActiveRecord::Migration
  def self.up
     create_table "targ_rep_es_cell_distribution_centres" do |t|
      t.string   "name"

      t.timestamps
    end
  end

  def self.down
    drop_table "targ_rep_es_cell_distribution_centres"
  end
end
