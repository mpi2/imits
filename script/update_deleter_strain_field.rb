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



<<<<<<< HEAD
  puts 'DTCC'
=======
  # 'DTCC'
>>>>>>> Monthly_activity_report
  puts 'DTCC and others centres breakdown'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC').result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_not_eq => 'DTCC').result.count
  puts 'No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0).result.count
  puts 'No of records to change / No of records that do not need to be changed'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_eq => 1).result.count

<<<<<<< HEAD
  'DTCC'
=======
>>>>>>> Monthly_activity_report
  a = PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0).result.all
  a.each {|rec| PhenotypeAttempt.find_by_id(rec.id).update_attributes(:deleter_strain_id => 1)}

  puts 'should be 0 / = to No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'DTCC', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_eq => 1).result.count


<<<<<<< HEAD
=======

    # 'JAX'
  puts 'JAX and others centres breakdown'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'JAX').result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_not_eq => 'JAX').result.count
  puts 'No of records that should have a deleter_strain set to 2'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'JAX', :number_of_cre_matings_successful_not_eq => 0).result.count
  puts 'No of records to change / No of records that do not need to be changed'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'JAX', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'JAX', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_eq => 2).result.count

  a = PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'JAX', :number_of_cre_matings_successful_not_eq => 0).result.all
  a.each {|rec| PhenotypeAttempt.find_by_id(rec.id).update_attributes(:deleter_strain_id => 2)}

  puts 'should be 0 / = to No of records that should have a deleter_strain set to 2'
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'JAX', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'JAX', :number_of_cre_matings_successful_not_eq => 0, :deleter_strain_id_eq => 2).result.count




>>>>>>> Monthly_activity_report

  raise 'rollback'

end