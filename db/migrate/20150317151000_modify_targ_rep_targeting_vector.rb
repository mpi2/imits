class ModifyTargRepTargetingVector < ActiveRecord::Migration
  def self.up
    add_column :targ_rep_targeting_vectors, :production_centre_auto_update, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :targ_rep_targeting_vectors, :production_centre_auto_update
  end

end