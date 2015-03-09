class ModifyCentre < ActiveRecord::Migration
  def self.up
    add_column :centres, :code, :string
  end

  def self.down
    remove_column :centres, :code
  end

end