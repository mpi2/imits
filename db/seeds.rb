# encoding: utf-8

MiAttemptStatus.find_or_create_by_description('In progress', :id => 1)
MiAttemptStatus.find_or_create_by_description('Good', :id => 2)

Object.new.instance_eval do
  def set_up_strains(strain_ids_class, filename)
    strains_list = File.read(Rails.root + "config/strains/#{filename}.txt").split("\n")
    strains_list.each do |strain_name|
      next if strain_name.empty?
      strain = Strain.find_or_create_by_name(strain_name)
      strain_ids_class.find_or_create_by_id(strain.id)
    end
  end

  set_up_strains Strain::BlastStrainId, :blast_strains
  set_up_strains Strain::ColonyBackgroundStrainId, :colony_background_strains
  set_up_strains Strain::TestCrossStrainId, :test_cross_strains
end

['na', 'fail', 'pass'].each do |desc|
  QcStatus.find_or_create_by_description(desc)
end
