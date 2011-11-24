class AddOrderByColumnToMiAttemptStatuses < ActiveRecord::Migration
  def self.up
    add_column :mi_attempt_statuses, :order_by, :integer, :null => false, :default => 0
    change_column :mi_attempt_statuses, :order_by, :integer, :default => nil
  end

  def self.down
    remove_column :mi_attempt_statuses, :order_by
  end
end
