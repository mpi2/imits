class AddConditionalTm1cAndIgnoreAvailableMice < ActiveRecord::Migration
  def up
    add_column :mi_plans, :conditional_tm1c, :boolean, :default => false, :null => false
    add_column :mi_plans, :ignore_avaliable_mice, :boolean, :default => false, :null => false
  end

  def down
    remove_column :mi_plans, :conditional_tm1c
    remove_column :mi_plans, :ignore_avaliable_mice
  end
end
