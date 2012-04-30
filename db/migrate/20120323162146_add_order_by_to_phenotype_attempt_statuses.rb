class AddOrderByToPhenotypeAttemptStatuses < ActiveRecord::Migration
  def self.up
    add_column :phenotype_attempt_statuses, :order_by, :integer
  end

  def self.down
    remove_column :phenotype_attempt_statuses, :order_by
  end
end
