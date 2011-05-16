#!/usr/bin/env ruby
#encoding: utf-8

[
  ['blast_strain', 'blast_strains'],
  ['test_cross_strain', 'test_cross_strains'],
  ['back_cross_strain', 'colony_background_strains']
].each do |old_name, new_name|

  new_table_name = Strain.const_get(new_name.singularize.camelize)
  db_strains = new_table_name.all.map(&:name)

  distinct_old_strains = Old::MiAttempt.scoped(:select => "distinct #{old_name}").map {|i| i[old_name]}

  strains_needing_cleanup = []

  distinct_old_strains.each do |i|
    next if i.nil?
    found = db_strains.find {|a| a == i}
    unless found
      strains_needing_cleanup << i
    end
  end

  strains_needing_cleanup= strains_needing_cleanup.sort_by {|i| i.to_s.upcase}

  y({new_name.humanize => strains_needing_cleanup})
end
