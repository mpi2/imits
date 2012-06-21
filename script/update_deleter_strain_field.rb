#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

  # 'WTSI'
  puts 'Total number of phenotype attempts'
  puts PhenotypeAttempt.count
  puts ''
  puts ''
  puts 'WTSI'
  puts 'WTSI and others centres breakdown'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI').result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_not_eq => 'WTSI').result.count
  puts 'No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI', :number_of_cre_matings_successful_not_eq => 0).result.count
  puts 'No of records to change / No of records that do not need to be changed'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_eq => 1).result.count

  a = PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI', :number_of_cre_matings_successful_not_eq => 0).result.all
  a.each {|rec| PhenotypeAttempt.find_by_id(rec.id).update_attributes(:deleter_strain_id => 1)}

  puts 'should be 0 / = to No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_eq => 1).result.count



  puts 'DTCC'
  puts 'DTCC and others centres breakdown'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC').result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_not_eq => 'DTCC').result.count
  puts 'No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0).result.count
  puts 'No of records to change / No of records that do not need to be changed'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_eq => 1).result.count

  'DTCC'
  a = PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0).result.all
  a.each {|rec| PhenotypeAttempt.find_by_id(rec.id).update_attributes(:deleter_strain_id => 1)}

  puts 'should be 0 / = to No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_eq => 1).result.count



  raise 'rollback'

end