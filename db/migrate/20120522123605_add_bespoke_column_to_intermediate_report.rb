class AddBespokeColumnToIntermediateReport < ActiveRecord::Migration
  def self.up
    add_column :intermediate_report, :is_bespoke_allele, :boolean
  end

  def self.down
    remove_column :intermediate_report, :is_bespoke_allele
  end
end
