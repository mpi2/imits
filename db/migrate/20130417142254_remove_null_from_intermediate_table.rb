class RemoveNullFromIntermediateTable < ActiveRecord::Migration
  def up
    change_column :intermediate_report, :allele_symbol, :string, :null => true
    change_column :intermediate_report, :genetic_background, :string, :null => true
    change_column :intermediate_report, :production_centre, :string, :null => true
    change_column :intermediate_report, :sub_project, :string, :null => true
  end

  def down
    IntermediateReport.where(:allele_symbol => nil).each {|r| r.update_attribute(:allele_symbol, '')}
    IntermediateReport.where(:genetic_background => nil).each {|r| r.update_attribute(:genetic_background, '')}
    IntermediateReport.where(:production_centre => nil).each {|r| r.update_attribute(:production_centre, '')}
    IntermediateReport.where(:sub_project => nil).each {|r| r.update_attribute(:sub_project, '')}

    change_column :intermediate_report, :allele_symbol, :string, :null => false
    change_column :intermediate_report, :genetic_background, :string, :null => false
    change_column :intermediate_report, :production_centre, :string, :null => false
    change_column :intermediate_report, :sub_project, :string, :null => false
  end
end
