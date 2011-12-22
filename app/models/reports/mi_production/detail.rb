# encoding: utf-8

class Reports::MiProduction::Detail
  def self.generate
    report = ReportCache.find_by_name!('mi_production_intermediate').to_table
    report.rename_columns('Overall Status' => 'Status')
    wanted_columns = [
      'Consortium',
      'Sub-Project',
      'Priority',
      'Production Centre',
      'Status',
      'Assigned Date',
      'Assigned - ES Cell QC In Progress Date',
      'Assigned - ES Cell QC Complete Date',
      'Micro-injection in progress Date',
      'Genotype confirmed Date',
      'Micro-injection aborted Date',
      'Phenotype Attempt Registered Date',
      'Cre Excision Started Date',
      'Cre Excision Complete Date',
      'Phenotyping Complete Date',
      'Phenotype Attempt Aborted Date'
    ]
    report.reorder(wanted_columns)
    return report
  end
end
