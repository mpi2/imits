class AddCreExcisionRequiredToPhenotypeAttempts < ActiveRecord::Migration
  def self.up
    add_column :phenotype_attempts, :cre_excision_required, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :phenotype_attempts, :cre_excision_required
  end
end
