class AddDoNotCountTowardsCompletenessToPhenotypingProductionTable < ActiveRecord::Migration
  def self.up
    add_column :phenotyping_productions, :do_not_count_towards_completeness, :boolean, default: false 
  end

  def self.down
    remove_column :phenotyping_productions, :do_not_count_towards_completeness
  end
end
