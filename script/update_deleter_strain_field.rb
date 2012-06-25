#!/usr/bin/env ruby

#ApplicationModel.audited_transaction do
  puts 'Total number of phenotype attempts'
  puts PhenotypeAttempt.count
  puts ''
  puts ''
  puts 'BaSH'
  puts 'BaSH and others centres breakdown'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'BaSH').result.count
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_not_eq => 'BaSH').result.count
  puts 'No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'BaSH', :number_of_cre_matings_started_not_eq => 0).result.count
  puts 'No of records to change / No of records that do not need to be changed'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'BaSH', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'BaSH', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_eq => 1).result.count

  a = PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'BaSH', :number_of_cre_matings_started_not_eq => 0).result.all
  a.each {|rec| PhenotypeAttempt.find_by_id!(rec.id).update_attributes(:deleter_strain_id => 1)}

  puts 'should be 0 / = to No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'BaSH', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'BaSH', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_eq => 1).result.count


  puts 'DTCC'
  # 'DTCC'
  puts 'DTCC and others centres breakdown'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'DTCC').result.count
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_not_eq => 'DTCC').result.count
  puts 'No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'DTCC', :number_of_cre_matings_started_not_eq => 0).result.count
  puts 'No of records to change / No of records that do not need to be changed'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'DTCC', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'DTCC', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_eq => 1).result.count

  puts  'DTCC'
  a = PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'DTCC', :number_of_cre_matings_started_not_eq => 0).result.all
  a.each {|rec| PhenotypeAttempt.find_by_id!(rec.id).update_attributes(:deleter_strain_id => 1)}

  puts 'should be 0 / = to No of records that should have a deleter_strain set to 1'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'DTCC', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'DTCC', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_eq => 1).result.count


    # 'JAX'
  puts 'JAX and others centres breakdown'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'JAX').result.count
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_not_eq => 'JAX').result.count
  puts 'No of records that should have a deleter_strain set to 2'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'JAX', :number_of_cre_matings_started_not_eq => 0).result.count
  puts 'No of records to change / No of records that do not need to be changed'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'JAX', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'JAX', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_eq => 2).result.count

  a = PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'JAX', :number_of_cre_matings_started_not_eq => 0).result.all
  a.each {|rec| PhenotypeAttempt.find_by_id!(rec.id).update_attributes(:deleter_strain_id => 2)}

  puts 'should be 0 / = to No of records that should have a deleter_strain set to 2'
  puts PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'JAX', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_null => 1).result.count
  puts PhenotypeAttempt.search(:mi_plan_production_consortium_name_eq => 'JAX', :number_of_cre_matings_started_not_eq => 0, :deleter_strain_id_eq => 2).result.count

#  raise 'rollback'

#end