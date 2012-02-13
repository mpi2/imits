#!/usr/bin/env ruby

def komp2_pts
  mis = MiAttempt.search(
    :mi_plan_consortium_name_in => ['BaSH', 'JAX'],
    :mi_attempt_status_description_eq => 'Genotype confirmed').result
  puts "#{mis.size} KOMP2 PTS created:"
  mis.each do |mi|
    pt = PhenotypeAttempt.create!(:mi_attempt => mi)
    puts pt.colony_name
  end
  puts
end

def ucd_pts
  es_cell_names = %w{
    10011B-G3
    DEPD00504_7_G06
    EPD0097_4_H01
    10174A-F5
  }
  mis = MiAttempt.search(:es_cell_name_in => es_cell_names).result
  puts "#{mis.size} JAX/UCD PTS created:"
  mis.each do |mi|
    plan_params = {
      :consortium_id => Consortium.find_by_name!('JAX').id,
      :production_centre_id => Centre.find_by_name!('JAX').id,
      :gene_id => mi.gene.id
    }
    plan = MiPlan.where(plan_params).first
    if ! plan
      plan = MiPlan.create!(plan_params.merge(:status => MiPlan::Status[:Assigned], :priority => MiPlan::Priority.find_by_name!(:High)))
    end

    pt = PhenotypeAttempt.create!(:mi_attempt => mi, :mi_plan => plan)
    puts pt.colony_name
  end
  puts

  mis = MiAttempt.search(:colony_name_in => %w{UCD-EPD0396_4_E05-1 MASL}).result
  puts "#{mis.size} NorCOMM2/UCD PTS created:"
  mis.each do |mi|
    plan_params = {
      :consortium_id => Consortium.find_by_name!('NorCOMM2').id,
      :production_centre_id => Centre.find_by_name!('TCP').id,
      :gene_id => mi.gene.id
    }
    plan = MiPlan.where(plan_params).first
    if ! plan
      plan = MiPlan.create!(plan_params.merge(:status => MiPlan::Status[:Assigned], :priority => MiPlan::Priority.find_by_name!(:High)))
    end

    pt = PhenotypeAttempt.create!(:mi_attempt => mi, :mi_plan => plan)
    puts pt.colony_name
  end
  puts
end

MiAttempt.transaction do
  Audit.as_user(User.find_by_email!('htgt@sanger.ac.uk')) do
    komp2_pts
    ucd_pts
  end
end
