#!/usr/bin/env ruby

require 'pp'
require 'open-uri'
require 'net/ftp'
#require 'fileutils'

# read folder

url = 'ftp.informatics.jax.org'
file_list = []

ftp = Net::FTP.new(url)
ftp.login
files = ftp.chdir('pub/IKMC')
files = ftp.list()
#pp files

files.each do |file|
  file_list.push file.scan( /(mgi_allele_ikmc.+)/).last.first if file !~ /current/
end

#pp file_list


#exit

# read file

data = []

#hash_counts = {1 => 0, 2 => 0, 3 => 0}

url = 'ftp://ftp.informatics.jax.org/pub/IKMC/'

file_list.each do |file|
  open(url + file, :proxy => nil) do |f|
    # f.each_line {|line| p line}
    f.each_line do |line|
      row = line.strip.split(/\t/)
      hash = {'Colony name' => row[0], 'MGI accession id' => row[1], 'Allele name' => row[2]}
      data.push hash
    end
  end
end

#pp data

#exit

data = data.sort { |a, b| a['Colony name'] <=> b['Colony name'] }

#CSV.open('/nfs/users/nfs_r/re4/Desktop/IKMC.csv', "wb") do |csv|
#  csv << data[0].keys
#  data.each do |row|
#    csv << row.values
#    #break
#  end
#end

PhenotypeAttempt.transaction do
  data.each do |row|
    clean_name = row['Colony name'].gsub("&lt;", '<').gsub("&gt;", '>')
    pa = PhenotypeAttempt.find_by_colony_name clean_name
    puts "#### cannot find '#{row['Colony name']}' - #{row.to_s}" if ! pa
    next if ! pa
    pa.allele_name = row['Allele name']
    pa.mgi_accession_id = row['MGI accession id']
    pa.save!
  end

  #raise "rollback!"
end

#
##colony_name
#
#pas = []
#pa_hash = {}
#PhenotypeAttempt.all.each do |pa|
#  pa_hash[pa.colony_name] ||= 0
#  pa_hash[pa.colony_name] += 1
#end
#
##pp pa_hash
#
#CSV.open('/nfs/users/nfs_r/re4/Desktop/PhenotypeAttempt.csv', "wb") do |csv|
#  csv << ['Colony name']
#  pa_hash.keys.each do |key|
#    raise "not unique!" if pa_hash[key].to_i > 1
#    csv << [key]
#  end
#end

#exit
#
#Rails.logger.info "Load Phenotype Attempt info"
#Rails.logger.info "downloading mgi_allele_ikmc.txt.current"
#
#url = 'ftp://ftp.informatics.jax.org/pub/IKMC/mgi_allele_ikmc.txt.current'
#open(url, :proxy => nil) do |file|
#  file.each_line do |line|
#    row = line.strip.split(/\s+/)
#    data.push row
#  end
#end
#
#pp data
#
#PhenotypeAttempt.transaction do
#
#end
