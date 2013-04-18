class AmendStrainTable < ActiveRecord::Migration
  def up
    change_column :strains, :name, :string, :limit => 100
  end

  def down
    change_column :strains, :string, :limit => 50
  end
end
