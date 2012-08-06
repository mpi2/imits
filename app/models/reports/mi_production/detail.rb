# encoding: utf-8

class Reports::MiProduction::Detail
  def self.generate(current_user)
    report = ReportCache.find_by_name_and_format!('mi_production_intermediate', 'csv').to_table
    report.rename_columns('Overall Status' => 'Status')
    if current_user.can_see_sub_project?
      wanted_columns = [
        'Consortium',
        'Sub-Project',
        'Is Bespoke Allele',
        'Priority',
        'Production Centre',
        'Gene',
        'Status',
        'Assigned Date',
        'Assigned - ES Cell QC In Progress Date',
        'Assigned - ES Cell QC Complete Date',
        'Micro-injection in progress Date',
        'Chimeras obtained Date',
        'Genotype confirmed Date',
        'Micro-injection aborted Date',
        'Phenotype Attempt Registered Date',
        'Cre Excision Started Date',
        'Cre Excision Complete Date',
        'Phenotyping Complete Date',
        'Phenotype Attempt Aborted Date'
      ]
    else
      wanted_columns = [
        'Consortium',
        'Is Bespoke Allele',
        'Priority',
        'Production Centre',
        'Gene',
        'Status',
        'Assigned Date',
        'Assigned - ES Cell QC In Progress Date',
        'Assigned - ES Cell QC Complete Date',
        'Micro-injection in progress Date',
        'Chimeras obtained Date',
        'Genotype confirmed Date',
        'Micro-injection aborted Date',
        'Phenotype Attempt Registered Date',
        'Cre Excision Started Date',
        'Cre Excision Complete Date',
        'Phenotyping Complete Date',
        'Phenotype Attempt Aborted Date'
      ]
    end
    report.reorder(wanted_columns)
    return report
  end
end
