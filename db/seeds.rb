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

{
  'BaSH'            => ['KOMP2', 'Baylor, Sanger, Harwell'],
  'DTCC'            => ['KOMP2', 'Davis-Toronto-Charles River-CHORI'],
  'DTCC-KOMP'       => ['KOMP', 'Davis-Toronto-Charles River-CHORI'],
  'EUCOMM-EUMODIC'  => ['EUCOMM / EUMODIC', nil],
  'Helmholtz GMC'   => ['Infrafrontier/BMBF', 'Helmholtz Muenchen'],
  'JAX'             => ['KOMP2', 'The Jackson Laboratory'],
  'MARC'            => ['China', 'Model Animarl Research Centre, Nanjing University'],
  'MGP'             => ['Wellcome Trust', 'Mouse Genetics Project, WTSI'],
  'MGP-KOMP'        => ['KOMP / Wellcome Trust', 'Mouse Genetics Project, WTSI'],
  'Monterotondo'    => ['European Union', 'Monterotondo Institute for Cell Biology (CNR)'],
  'MRC'             => ['MRC', 'MRC - Harwell'],
  'NorCOMM2'        => ['Genome Canada', 'NorCOMM2'],
  'Phenomin'        => ['Phenomin', 'ICS'],
  'RIKEN BRC'       => ['Japanese government', 'RIKEN BRC']
}.each do |name,details|
  cons = Consortium.find_or_create_by_name(:name => name)
  if cons.funding.blank?
    cons.funding = details[0]
    cons.participants = details[1]
    cons.save!
  end
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
  'WTSI',
  'JAX'
].each do |name|
  Centre.find_or_create_by_name name
end

{
  'Interest'               => [10, 'Interest - A consortium has expressed an interest to micro-inject this gene'],
  'Conflict'               => [20, 'Conflict - More than one consortium has expressed an intrest in micro-injecting this gene'],
  'Declined - GLT Mouse'   => [30, 'Declined - A GLT mouse is already recorded in iMits'],
  'Declined - MI Attempt'  => [40, 'Declined - An active micro-injection attempt is already in progress'],
  'Declined - Conflict'    => [50, 'Declined - This gene is already assigned in another planned micro-injection'],
  'Assigned'               => [60, 'Assigned - A single consortium has expressed an intrest in injecting this gene'],
  'Assigned - ES Cell QC In Progress' => [70, 'Assigned - The ES cells are currently being QCed by the production centre'],
  'Assigned - ES Cell QC Complete'    => [80, 'Assigned - ES cells have passed the QC phase and are ready for micro-injection'],
  'Inactive'               => [90, 'Inactive - A consortium/production centre has failed micro-injections on this gene dated over 6 months ago - they have given up']
}.each do |name,details|
  mi_plan_status = MiPlanStatus.find_or_create_by_name(name)
  mi_plan_status.description = details[1]
  mi_plan_status.order_by = details[0]
  mi_plan_status.save! if mi_plan_status.changed?
end

{
  'High'   => 'Estimated injection in the next 0-4 months',
  'Medium' => 'Estimated injection in the next 5-8 months',
  'Low'    => 'Estimated injection in the next 9-12 months'
}.each do |name, description|
  mi_plan_priority = MiPlanPriority.find_or_create_by_name(:name => name)
  mi_plan_priority.description = description
  mi_plan_priority.save! if mi_plan_priority.changed?
end
