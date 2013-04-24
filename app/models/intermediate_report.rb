class IntermediateReport < ActiveRecord::Base
  self.table_name = :intermediate_report

  acts_as_reportable

  require_dependency 'intermediate_report/generate'

  belongs_to :phenotype_attempt, :primary_key => 'colony_name', :foreign_key => 'phenotype_attempt_colony_name'

  ## Class methods

  def self.generate(report)
    IntermediateReport.transaction do
      IntermediateReport.destroy_all
      report.each do |row|
        hash = {}
        report.column_names.each do |column_name|
          hash[column_name.gsub(' - ', '_').gsub(' ', '_').underscore.to_sym] = row[column_name]
          hash[column_name.gsub(' - ', '_').gsub(' ', '_').underscore.to_sym] = row[column_name] == 'Yes' if column_name == 'Is Bespoke Allele'
        end
        IntermediateReport.create hash
      end
    end
  end
  
end
