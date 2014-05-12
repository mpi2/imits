#!/usr/bin/env ruby

require 'pp'

def read_csv filename
  counter = 0
  data = {}
  CSV.foreach(filename, :headers => true) do |row|
    hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
    data[hash['mgi_accession_id']] = hash
    counter += 1
  end
  data
end

home = Dir.home

alleles_new = read_csv "#{home}/Desktop/allele-localhost.csv"

alleles_old = read_csv "#{home}/Desktop/allele-bytemark.csv"

targets = []

alleles_old.keys.each do |key|
  if alleles_new.has_key? key
   # next if ! alleles_new[key]['vector_project_ids'] || ! alleles_old[key]['vector_project_ids']
    #pp alleles_new[key]
    if alleles_new[key]['vector_project_ids'].to_s.split(',').sort.uniq != alleles_old[key]['vector_project_ids'].to_s.split(',').sort.uniq
      #next if alleles_new[key]['vector_project_ids'].to_s.split(',').sort.uniq.size != 2
      #next if alleles_old[key]['vector_project_ids'].to_s.split(',').sort.uniq.size != 1
      ##targets.push [alleles_new[key]['marker_symbol'], key, alleles_new[key]['vector_project_ids'].to_s.split(',').sort.uniq, alleles_old[key]['vector_project_ids'].to_s.split(',').sort.uniq]
      targets.push({
        'marker_symbol' => alleles_new[key]['marker_symbol'],
        'mgi_accession_id' => key,
        'project_ids_old' => alleles_old[key]['project_ids'].to_s.split(',').sort.uniq,
        'project_ids_new' => alleles_new[key]['project_ids'].to_s.split(',').sort.uniq,
        'vector_project_ids_old' => alleles_old[key]['vector_project_ids'].to_s.split(',').sort.uniq,
        'vector_project_ids_new' => alleles_new[key]['vector_project_ids'].to_s.split(',').sort.uniq,
        'check' => alleles_old[key]['vector_project_ids'].to_s.split(',').sort.uniq.size > 0
      })
      # break if targets.size >= 10
    end
  end
end

puts "#### size: #{targets.size}"
pp targets
