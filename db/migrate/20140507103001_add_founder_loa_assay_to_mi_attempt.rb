class AddFounderLoaAssayToMiAttempt < ActiveRecord::Migration
  def change
    add_column :mi_attempts, :founder_loa_num_assays, :integer
    add_column :mi_attempts, :founder_loa_num_positive_results, :integer
  end
end
