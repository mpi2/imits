class RemoveDepositedMaterialIdFromMiAttempts < ActiveRecord::Migration
  def self.up
    remove_column :mi_attempts, :deposited_material_id
  end

  def self.down
    add_column :mi_attempts, :deposited_material_id, :integer, :null => false
  end
end
