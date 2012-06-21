#!/usr/bin/env ruby

# 'WTSI'
a = PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI', :number_of_cre_matings_successful_not_eq => 0).result.all
a.each {|rec| PhenotypeAttempt.find_by_id(rec.id).update_attributes(:deleter_strain_id => 1)}

# 'WTSI'
# a = PhenotypeAttempt.search(:mi_plan_production_centre_name_eq => 'WTSI', :number_of_cre_matings_successful_not_eq => 0).result.all
# a.each {|rec| PhenotypeAttempt.find_by_id(rec.id).update_attributes(:deleter_strain_id => 1)}