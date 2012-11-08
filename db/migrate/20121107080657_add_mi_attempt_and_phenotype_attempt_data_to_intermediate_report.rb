class AddMiAttemptAndPhenotypeAttemptDataToIntermediateReport < ActiveRecord::Migration
  def self.up
    add_column :intermediate_report, :mi_attempt_colony_name, :string
    add_column :intermediate_report, :mi_attempt_consortium, :string
    add_column :intermediate_report, :mi_attempt_production_centre, :string
    add_column :intermediate_report, :phenotype_attempt_colony_name, :string
  end

  def self.down
    remove_column :intermediate_report, :phenotype_attempt_colony_name
    remove_column :intermediate_report, :mi_attempt_production_centre
    remove_column :intermediate_report, :mi_attempt_consortium
    remove_column :intermediate_report, :mi_attempt_colony_name
  end
end
