class AddHaploEssentialToMiAttempts < ActiveRecord::Migration
  def change
  	add_column :mi_attempts, :haplo_essential, :boolean, default: false
  end
end
