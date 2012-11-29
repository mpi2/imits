#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

# allele_symbol_superscript_template | count
#------------------------------------+-------
# tm1(CreERT2_EGFP)Wtsi              |     4
# tm1(EUCOMM)Wtsi                    |     1
# tm1(KOMP)Wtsi                      |   149
# tm2(KOMP)Vlcg                      |     1
# <sup>sv</sup>                      |     1
# tm1(KOMP)Vlcg                      |   766
# tm2(KOMP)Wtsi                      |     5
# tm2(EUCOMM)Wtsi                    |     1
# Gt(IST12384G7)Tigm                 |     1
# tm1(KOMP)Mbp                       |    60
#(10 rows)

#['tm1(CreERT2_EGFP)Wtsi', 'tm1(EUCOMM)Wtsi', 'tm1(KOMP)Wtsi','tm2(KOMP)Vlcg', '<sup>sv</sup>', 'tm1(KOMP)Vlcg','tm2(KOMP)Wtsi','tm2(EUCOMM)Wtsi', 'Gt(IST12384G7)Tigm','tm1(KOMP)Mbp']
#select allele_symbol_superscript_template,count(*) from es_cells where allele_symbol_superscript_template not like '%@%'
#select * from es_cells where allele_symbol_superscript_template not like '%@%'

DEBUG = true

puts "ENV: #{Rails.env}"

es_cells = EsCell.all(:conditions => ["allele_symbol_superscript_template not like ?", '%@%'])

es_cells.each do |es_cell|
  next if es_cell.allele_symbol_superscript_template == 'Gt(IST12384G7)Tigm'
  raise "Unexpected \@ found!" if es_cell.allele_symbol_superscript_template =~ /@/
  old_es_cell = es_cell.allele_symbol_superscript_template
  new_es_cell = es_cell.allele_symbol_superscript_template.sub(/\(/, '@(')
  es_cell.allele_symbol_superscript_template = new_es_cell
  puts "Changing es_cell id #{es_cell.id} from '#{old_es_cell}' to '#{new_es_cell}'"
  es_cell.save!
end

puts "COUNT: #{es_cells.size}"

raise "Unexpected count!" if es_cells.size != 989
raise "rollback!" if DEBUG

end