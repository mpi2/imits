# encoding: utf-8

module Seeds
  def self.load(model_class, data)
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

Seeds.load MiAttemptStatus, [
  {:id => 1, :description => 'Micro-injection in progress init'},
  {:id => 2, :description => 'Genotype confirmed'},
  {:id => 3, :description => 'Micro-injection aborted'}
]

Seeds.set_up_strains Strain::BlastStrain, :blast_strains
Seeds.set_up_strains Strain::ColonyBackgroundStrain, :colony_background_strains
Seeds.set_up_strains Strain::TestCrossStrain, :test_cross_strains

Seeds.load QcResult, [
  {:id => 1, :description => 'na'},
  {:id => 2, :description => 'fail'},
  {:id => 3, :description => 'pass'},
]

Seeds.load DepositedMaterial, [
  {:id => 1, :name => 'Frozen embryos'},
  {:id => 2, :name => 'Live mice'},
  {:id => 3, :name => 'Frozen sperm'}
]

Seeds.load Consortium, [
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

Seeds.load Centre, [
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

Seeds.load MiPlanStatus, [
  {:order_by => 10,  :id => 2,  :name => 'Interest', :description => 'Interest - A consortium has expressed an interest to micro-inject this gene'},
  {:order_by => 20,  :id => 3,  :name => 'Conflict', :description => 'Conflict - More than one consortium has expressed an interest in micro-injecting this gene'},
  {:order_by => 30,  :id => 4,  :name => 'Inspect - GLT Mouse', :description => 'Inspect - A GLT mouse is already recorded in iMits'},
  {:order_by => 40,  :id => 5,  :name => 'Inspect - MI Attempt', :description => 'Inspect - An active micro-injection attempt is already in progress'},
  {:order_by => 50,  :id => 6,  :name => 'Inspect - Conflict', :description => 'Inspect - This gene is already assigned in another planned micro-injection'},
  {:order_by => 60,  :id => 1,  :name => 'Assigned', :description => 'Assigned - A single consortium has expressed an interest in injecting this gene'},
  {:order_by => 70,  :id => 8,  :name => 'Assigned - ES Cell QC In Progress', :description => 'Assigned - The ES cells are currently being QCed by the production centre'},
  {:order_by => 80,  :id => 9,  :name => 'Assigned - ES Cell QC Complete', :description => 'Assigned - ES cells have passed the QC phase and are ready for micro-injection'},
  {:order_by => 85,  :id => 10, :name => 'Aborted - ES Cell QC Failed', :description => 'Aborted - ES cells have failed the QC phase, and micro-injection cannot proceed'},
  {:order_by => 90,  :id => 7,  :name => 'Inactive', :description => 'Inactive - A consortium/production centre has failed micro-injections on this gene dated over 6 months ago - they have given up'},
  {:order_by => 100, :id => 11, :name => 'Withdrawn', :description => 'Withdrawn - Interest in micro-injecting this gene was withdrawn by the parties involved'}
]

Seeds.load MiPlanPriority, [
  {:id => 1, :name => 'High', :description => 'Estimated injection in the next 0-4 months'},
  {:id => 2, :name => 'Medium', :description => 'Estimated injection in the next 5-8 months'},
  {:id => 3, :name => 'Low', :description => 'Estimated injection in the next 9-12 months'}
]
