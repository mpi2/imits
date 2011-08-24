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
  'DTCC-KOMP',
  'EUCOMM-EUMODIC',
  'Helmholtz GMC',
  'MARC',
  'Monterotondo',
  'MGP',
  'MGP-KOMP',
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
  'DTCC',
  'HMGU',
  'ICS',
  'MARC',
  'Monterotondo',
  'MRC - Harwell',
  'Oulu',
  'RIKEN BRC',
  'TCP',
  'UCD',
  'WTSI'
].each do |name|
  Centre.find_or_create_by_name name
end

{
  'Interest'               => [10,'Interest - A consortium has expressed an intrest to micro-inject this gene'],
  'Conflict'               => [20,'Conflict - More than one consortium has expressed an intrest in micro-injecting this gene'],
  'Declined - GLT Mouse'   => [30,'Declined - A GLT mouse is already recorded in iMits'],
  'Declined - MI Attempt'  => [40,'Declined - An active micro-injection attempt is already in progress'],
  'Declined - Conflict'    => [50,'Declined - This gene is already assigned in another planned micro-injection'],
  'Assigned'               => [60,'Assigned - A single consortium has expressed an intrest in injecting this gene']
}.each do |name, details|
  mi_plan_status = MiPlanStatus.find_or_create_by_name(:name => name)
  if mi_plan_status.description.blank?
    mi_plan_status.description = details[1]
    mi_plan_status.order_by = details[0]
    mi_plan_status.save!
  end
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
