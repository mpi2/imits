# encoding: utf-8

[
  'Micro-injection in progress',
  'Genotype confirmed',
  'Micro-injection aborted',
].each do |description|
  MiAttemptStatus.find_or_create_by_description description
end

Object.new.instance_eval do
  def set_up_strains(strain_ids_class, filename)
    strains_list = File.read(Rails.root + "config/strains/#{filename}.txt").split("\n")
    strains_list.each do |strain_name|
      next if strain_name.empty?
      strain = Strain.find_or_create_by_name(strain_name)
      strain_ids_class.find_or_create_by_id(strain.id)
    end
  end

  set_up_strains Strain::BlastStrain, :blast_strains
  set_up_strains Strain::ColonyBackgroundStrain, :colony_background_strains
  set_up_strains Strain::TestCrossStrain, :test_cross_strains
end

['na', 'fail', 'pass'].each do |desc|
  QcResult.find_or_create_by_description(desc)
end

['Frozen embryos', 'Live mice', 'Frozen sperm'].each do |name|
  DepositedMaterial.find_or_create_by_name name
end

[
  'BaSH',
  'DTCC',
  'EUCOMM-EUMODIC',
  'Helmholtz GMC',
  'MARC',
  'MGP',
  'MRC',
  'NorCOMM2',
  'PHENOMIN',
  'RIKEN BRC'
].each do |name|
  Consortium.find_or_create_by_name name
end

[
  'APN',
  'BCM',
  'CNB',
  'HMGU',
  'ICS',
  'MARC',
  'Monterotondo',
  'MRC - Harwell',
  'Oulu',
  'RIKEN BRC',
  'UCD',
  'WTSI'
].each do |name|
  Centre.find_or_create_by_name name
end

[
  'Interest',
  'Conflict',
  'Declined',
  'Assigned'
].each do |name|
  MiPlanStatus.find_or_create_by_name(name)
end

{
  'High'   => 'Estimated injection in the next 0-4 months',
  'Medium' => 'Estimated injection in the next 5-8 months',
  'Low'    => 'Estimated injection in the next 9-12 months'
}.each do |priority, description|
  mi_plan_priority = MiPlanPriority.find_or_create_by_name(:name => priority)
  if mi_plan_priority.description.blank?
    mi_plan_priority.description = description
    mi_plan_priority.save!
  end
end
