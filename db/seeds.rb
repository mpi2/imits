# encoding: utf-8

[
  'Micro-injection in progress',
  'Genotype confirmed',
  'Interest expressed',
  'Conflict of interest',
  'Declined',
  'Assigned'
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

['EUCOMM-EUMODIC','MGP','BASH'].each do |consortia|
  Consortium.find_or_create_by_name consortia
end
