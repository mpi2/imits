class ChangeMiAttemptMouseAlleleTypeLimit < ActiveRecord::Migration
  def self.up
    change_column :mi_attempts, :mouse_allele_type, :string, :limit => 2
  end

  def self.down
    change_column :mi_attempts, :mouse_allele_type, :string, :limit => 1
  end
end
