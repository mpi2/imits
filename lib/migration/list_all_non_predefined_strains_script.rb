#!/usr/bin/env ruby
#encoding: utf-8

all_blast_strains = Strain::BlastStrain.all.map(&:name)
all_colony_background_strains = Strain::ColonyBackgroundStrain.all.map(&:name)
all_test_cross_strains = Strain::TestCrossStrain.all.map(&:name)

Old::MiAttempt.all.each do |old_mi|
  dodgy_strains = {}

  if ! old_mi.blast_strain.blank? and ! all_blast_strains.include? old_mi.blast_strain
    dodgy_strains['blast_strain'] = old_mi.blast_strain
  end

  if ! old_mi.test_cross_strain.blank? and  ! all_test_cross_strains.include? old_mi.test_cross_strain
    dodgy_strains['test_cross_strain'] = old_mi.test_cross_strain
  end

  if ! old_mi.back_cross_strain.blank? and  ! all_colony_background_strains.include? old_mi.back_cross_strain
    dodgy_strains['back_cross_strain'] = old_mi.back_cross_strain
  end

  if ! dodgy_strains.empty?
    puts "#{old_mi.id.to_i}: #{dodgy_strains.map {|k, v| k + ': ' + v}.join ', '}"
  end
end
