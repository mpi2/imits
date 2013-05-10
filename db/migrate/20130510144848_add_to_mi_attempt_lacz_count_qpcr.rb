class AddToMiAttemptLaczCountQpcr < ActiveRecord::Migration
  def up
    add_column :mi_attempts, :qc_lacz_count_qpcr_id, :integer, :default => 1
  end

  def down
    remove_column :mi_attempts, :qc_lacz_count_qpcr_id
  end
end
