#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

  a = PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'BaSH', :number_of_cre_matings_started_not_eq => 0).result.all
  Rails.logger.info "update_deleter_strain_field: Updating #{a.count} deleter_strain for BaSH"
  a.each {|rec| PhenotypeAttempt.find_by_id!(rec.id).update_attributes!(:deleter_strain => DeleterStrain.find(2), :audit_comment => "update_deleter_strain_field.rb")}

  a = PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'DTCC', :number_of_cre_matings_started_not_eq => 0).result.all
  Rails.logger.info "update_deleter_strain_field: Updating #{a.count} deleter_strain for DTCC"
  a.each {|rec| PhenotypeAttempt.find_by_id!(rec.id).update_attributes!(:deleter_strain => DeleterStrain.find(2), :audit_comment => "update_deleter_strain_field.rb")}

  a = PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'JAX', :number_of_cre_matings_started_not_eq => 0).result.all
  Rails.logger.info "update_deleter_strain_field: Updating #{a.count} deleter_strain for JAX"
  a.each {|rec| PhenotypeAttempt.find_by_id!(rec.id).update_attributes!(:deleter_strain => DeleterStrain.find(3), :audit_comment => "update_deleter_strain_field.rb")}

  a = PhenotypeAttempt.search(:mi_plan_consortium_name_eq => 'Helmholtz GMC', :number_of_cre_matings_started_not_eq => 0).result.all
  Rails.logger.info "update_deleter_strain_field: Updating #{a.count} deleter_strain for Helmholtz GMC"
  a.each {|rec| PhenotypeAttempt.find_by_id!(rec.id).update_attributes!(:deleter_strain => DeleterStrain.find(4) , :audit_comment => "update_deleter_strain_field.rb")}

end