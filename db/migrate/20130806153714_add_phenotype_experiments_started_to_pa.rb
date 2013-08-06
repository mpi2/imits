class AddPhenotypeExperimentsStartedToPa < ActiveRecord::Migration
  def self.up
    add_column :phenotype_attempts, :phenotyping_experiments_started, :date
  end

  def self.down
    remove_column :phenotype_attempts, :phenotyping_experiments_started
  end
end
