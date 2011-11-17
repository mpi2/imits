# encoding: utf-8

module Seeds
  def self.load_data(model_class, data)
    data.each do |data|
      data_id = data.delete(:id)
      thing = model_class.find_by_id(data_id)
      if thing
        thing.attributes = data
      else
        thing = model_class.new(data)
        thing.id = data_id
      end

      thing.save! if thing.changed?
    end
  end

  def self.set_up_strains(strain_ids_class, filename)
    strains_list = File.read(Rails.root + "config/strains/#{filename}.txt").split("\n")
    strains_list.each do |strain_name|
      next if strain_name.empty?
      strain = Strain.find_or_create_by_name(strain_name)
      strain_ids_class.find_or_create_by_id(strain.id)
    end
  end
end

Seeds.load_data MiAttemptStatus, [
  {:id => 1, :description => 'Micro-injection in progress init'},
  {:id => 2, :description => 'Genotype confirmed'},
  {:id => 3, :description => 'Micro-injection aborted'}
]

Seeds.set_up_strains Strain::BlastStrain, :blast_strains
Seeds.set_up_strains Strain::ColonyBackgroundStrain, :colony_background_strains
Seeds.set_up_strains Strain::TestCrossStrain, :test_cross_strains

Seeds.load_data QcResult, [
  {:id => 1, :description => 'na'},
  {:id => 2, :description => 'fail'},
  {:id => 3, :description => 'pass'},
]

Seeds.load_data DepositedMaterial, [
  {:id => 1, :name => 'Frozen embryos'},
  {:id => 2, :name => 'Live mice'},
  {:id => 3, :name => 'Frozen sperm'}
]

Seeds.load_data Consortium, [
  {:id => 1,  :name => 'EUCOMM-EUMODIC', :funding => 'EUCOMM / EUMODIC', :participants => nil},
  {:id => 2,  :name => 'DTCC-KOMP',      :funding => 'KOMP', :participants => 'Davis-Toronto-Charles River-CHORI'},
  {:id => 3,  :name => 'MGP-KOMP',       :funding => 'KOMP / Wellcome Trust', :participants => 'Mouse Genetics Project, WTSI'},
  {:id => 4,  :name => 'BaSH',           :funding => 'KOMP2', :participants => 'Baylor, Sanger, Harwell'},
  {:id => 5,  :name => 'DTCC',           :funding => 'KOMP2', :participants => 'Davis-Toronto-Charles River-CHORI'},
  {:id => 6,  :name => 'Helmholtz GMC',  :funding => 'Infrafrontier/BMBF', :participants => 'Helmholtz Muenchen'},
  {:id => 7,  :name => 'JAX',            :funding => 'KOMP2', :participants => 'The Jackson Laboratory'},
  {:id => 8,  :name => 'MARC',           :funding => 'China', :participants => 'Model Animal Research Centre, Nanjing University'},
  {:id => 9,  :name => 'MGP',            :funding => 'Wellcome Trust', :participants => 'Mouse Genetics Project, WTSI'},
  {:id => 10, :name => 'Monterotondo',   :funding => 'European Union', :participants => 'Monterotondo Institute for Cell Biology (CNR)'},
  {:id => 11, :name => 'MRC',            :funding => 'MRC', :participants => 'MRC - Harwell'},
  {:id => 12, :name => 'NorCOMM2',       :funding => 'Genome Canada', :participants => 'NorCOMM2'},
  {:id => 13, :name => 'Phenomin',       :funding => 'Phenomin', :participants => 'ICS'},
  {:id => 14, :name => 'RIKEN BRC',      :funding => 'Japanese government', :participants => 'RIKEN BRC'}
]

Seeds.load_data Centre, [
  {:id => 1,  :name => 'WTSI'},
  {:id => 2,  :name => 'ICS'},
  {:id => 3,  :name => 'MRC - Harwell'},
  {:id => 4,  :name => 'Monterotondo'},
  {:id => 5,  :name => 'UCD'},
  {:id => 6,  :name => 'HMGU'},
  {:id => 7,  :name => 'CNB'},
  {:id => 8,  :name => 'APN'},
  {:id => 9,  :name => 'BCM'},
  {:id => 10, :name => 'Oulu'},
  {:id => 11, :name => 'TCP'},
  {:id => 12, :name => 'RIKEN BRC'},
  {:id => 13, :name => 'DTCC'},
  {:id => 14, :name => 'JAX'},
  {:id => 15, :name => 'MARC'}
]

{
  'Interest'               => [10, 'Interest - A consortium has expressed an interest to micro-inject this gene'],
  'Conflict'               => [20, 'Conflict - More than one consortium has expressed an intrest in micro-injecting this gene'],
  'Inspect - GLT Mouse'    => [30, 'Inspect - A GLT mouse is already recorded in iMits'],
  'Inspect - MI Attempt'   => [40, 'Inspect - An active micro-injection attempt is already in progress'],
  'Inspect - Conflict'     => [50, 'Inspect - This gene is already assigned in another planned micro-injection'],
  'Assigned'               => [60, 'Assigned - A single consortium has expressed an intrest in injecting this gene'],
  'Assigned - ES Cell QC In Progress' => [70, 'Assigned - The ES cells are currently being QCed by the production centre'],
  'Assigned - ES Cell QC Complete'    => [80, 'Assigned - ES cells have passed the QC phase and are ready for micro-injection'],
  'Aborted - ES Cell QC Failed'       => [85, 'Aborted - ES cells have failed the QC phase, and micro-injection cannot proceed'],
  'Inactive'               => [90, 'Inactive - A consortium/production centre has failed micro-injections on this gene dated over 6 months ago - they have given up'],
  'Withdrawn'              => [100, 'Withdrawn - Interest in micro-injecting this gene was withdrawn by the parties involved']
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
