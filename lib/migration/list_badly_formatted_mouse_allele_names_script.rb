#!/usr/bin/env ruby
#encoding: utf-8

Old::MiAttempt.all.each do |mi|
  next if mi.mouse_allele_name.blank?

  re = /\A([A-Za-z0-9]+)<sup>(tm\d)([a-e])?(\(\w+\)\w+)<\/sup>\Z/

  man_md = re.match(mi.mouse_allele_name)
  if ! man_md
    puts "MI(#{mi.id}) Clone(#{mi.clone.clone_name}): #{mi.mouse_allele_name.inspect} is bad mouse allele name"
  end

  an_md = re.match(mi.allele_name)
  if ! an_md
    puts "MI(#{mi.id}) Clone(#{mi.clone.clone_name}): #{mi.allele_name} is a bad allele name!"
  end

  if an_md[1] != man_md[1] or an_md[2] != man_md[2] or an_md[4] != man_md[4]
    puts "MI(#{mi.id}) Clone(#{mi.clone.clone_name}): MAN #{mi.mouse_allele_name} and AN #{mi.allele_name} do not correspond!"
  end

  mart_query = Clone.federated_query([mi.clone.clone_name])[0]

  puts "MI(#{mi.id}) Clone(#{mi.clone.clone_name}): MAN #{mi.mouse_allele_name}, MART #{mart_query['marker_symbol']}<sup>#{mart_query['allele_symbol_superscript']}</sup>"
end
