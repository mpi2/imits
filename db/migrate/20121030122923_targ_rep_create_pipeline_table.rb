class TargRepCreatePipelineTable < ActiveRecord::Migration
  def self.up
    create_table "targ_rep_pipelines" do |t|
      t.string   "name",       :null => false
      t.string   "description" ## Added for iMits
      
      t.timestamps
    end
  end

  def self.down
    drop_table "targ_rep_pipelines"
  end
end
