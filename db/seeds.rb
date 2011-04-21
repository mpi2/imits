# encoding: utf-8

MiAttemptStatus.find_or_create_by_description('In progress', :id => 1)
MiAttemptStatus.find_or_create_by_description('Good', :id => 2)

[BlastStrain, ColonyBackgroundStrain, TestCrossStrain].each do |strain_class|
  strains_list = File.read(Rails.root + "config/strains/#{strain_class.name.tableize}.txt").split("\n")
  strains_list.each do |strain_name|
    next if strain_name.empty?
    strain = Strain.find_or_create_by_name(strain_name)
    strain_class.find_or_create_by_id(strain.id)
  end
end
