class AddMiAttemptDistributionCentreMiAttemptFk < ActiveRecord::Migration
  def up
    add_foreign_key :mi_attempt_distribution_centres, :mi_attempts
  end

  def down
    remove_foreign_key :mi_attempt_distribution_centres, :mi_attempts
  end
end
