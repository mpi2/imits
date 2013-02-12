class AddRecoverableFields < ActiveRecord::Migration
  def self.change
    change_table :users do |t|
      t.recoverable      
    end
  end
end
