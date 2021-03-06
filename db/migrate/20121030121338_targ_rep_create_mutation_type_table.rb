class TargRepCreateMutationTypeTable < ActiveRecord::Migration
  def self.up
    create_table "targ_rep_mutation_types" do |t|
      t.string   "name",       :limit => 100, :null => false
      t.string   "code",       :limit => 100, :null => false
      
      t.timestamps
  end

  end

  def self.down
    drop_table "targ_rep_mutation_types"
  end
end
