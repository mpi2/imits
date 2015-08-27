class AddAlleleTargetToMiAttempt < ActiveRecord::Migration

  def self.up
    add_column :mi_attempts, :allele_target, :string
  end

  def self.down
    remove_column :mi_attempts, :allele_target
  end


end
