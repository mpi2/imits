#!/usr/bin/env ruby

require 'pp'

def read_csv_simple filename
  counter = 0
  data = []
  CSV.foreach(filename, :headers => true) do |row|
    hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
    data.push hash
    counter += 1
  end
  data
end

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

def compare_vector_project_ids
  home = Dir.home

  alleles_new = read_csv "#{home}/Desktop/allele-localhost.csv"

  alleles_old = read_csv "#{home}/Desktop/allele-bytemark.csv"

  targets = []

  alleles_old.keys.each do |key|
    if alleles_new.has_key? key
      if alleles_new[key]['vector_project_ids'].to_s.split(',').sort.uniq != alleles_old[key]['vector_project_ids'].to_s.split(',').sort.uniq
        targets.push({
          'marker_symbol' => alleles_new[key]['marker_symbol'],
          'mgi_accession_id' => key,
          'project_ids_old' => alleles_old[key]['project_ids'].to_s.split(',').sort.uniq,
          'project_ids_new' => alleles_new[key]['project_ids'].to_s.split(',').sort.uniq,
          'vector_project_ids_old' => alleles_old[key]['vector_project_ids'].to_s.split(',').sort.uniq,
          'vector_project_ids_new' => alleles_new[key]['vector_project_ids'].to_s.split(',').sort.uniq,
          'check' => alleles_old[key]['vector_project_ids'].to_s.split(',').sort.uniq.size > 0
        })
      end
    end
  end

  puts "#### size: #{targets.size}"
  pp targets
end

#def get_counts array, targets
#  array.each do |item|
#    targets['old']['types'][item['type']] ||= 0
#    targets['old']['types'][item['type']] += 1
#
#    attributes.each do |attribute|
#      targets['old'][attribute] ||= 0
#      targets['old'][attribute] += item[attribute].to_s.split(',').size
#    end
#  end
#end

def compare_type_counts
  home = Dir.home

  alleles_new = read_csv_simple "#{home}/Desktop/allele-localhost-all.csv"

  alleles_old = read_csv_simple "#{home}/Desktop/allele-bytemark-all.csv"

  targets = { 'old' => {'types' => {}}, 'new' => {'types' => {}}}

  attributes = %W{project_ids project_statuses vector_project_ids vector_project_statuses project_pipelines}

  alleles_old.each do |item|
    targets['old']['types'][item['type']] ||= 0
    targets['old']['types'][item['type']] += 1

    attributes.each do |attribute|
      targets['old'][attribute] ||= 0
      targets['old'][attribute] += item[attribute].to_s.split(',').size
    end
  end

  alleles_new.each do |item|
    targets['new']['types'][item['type']] ||= 0
    targets['new']['types'][item['type']] += 1

    attributes.each do |attribute|
      targets['new'][attribute] ||= 0
      targets['new'][attribute] += item[attribute].to_s.split(',').size
    end
  end

  targets['old']["all"] = alleles_old.size
  targets['new']["all"] = alleles_new.size

  pp targets
end

compare_type_counts
