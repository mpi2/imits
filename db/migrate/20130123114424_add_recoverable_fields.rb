class AddRecoverableFields < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.recoverable      
    end
  end

  def self.down
  end
end
