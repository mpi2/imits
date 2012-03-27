class AddOrderByToMiAttemptStatuses < ActiveRecord::Migration
  def self.up
    add_column :mi_attempt_statuses, :order_by, :integer
  end

  def self.down
    remove_column :mi_attempt_statuses, :order_by
  end
end
