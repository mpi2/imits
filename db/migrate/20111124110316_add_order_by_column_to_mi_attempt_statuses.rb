class AddOrderByColumnToMiAttemptStatuses < ActiveRecord::Migration
  def self.up
    add_column :mi_attempt_statuses, :order_by, :integer, :null => true
    execute('UPDATE mi_attempt_statuses SET order_by = 0')
    change_column :mi_attempt_statuses, :order_by, :integer, :null => false
  end

  def self.down
    remove_column :mi_attempt_statuses, :order_by
  end
end
