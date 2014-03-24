require 'pp'
require 'open-uri'
require 'net/ftp'

namespace :jax_phenotypes do

  def get_files
    url = 'ftp.informatics.jax.org'
    file_list = []

    ftp = Net::FTP.new(url)
    ftp.login
    files = ftp.chdir('pub/IKMC')
    files = ftp.list()

    files.each do |file|
      file_list.push file.scan( /(mgi_allele_ikmc.+)/).last.first if file !~ /current/
    end

    ftp.close

    file_list
  end

  def read_data filename
    data = []

    url = 'ftp://ftp.informatics.jax.org/pub/IKMC/'

    open(url + filename, :proxy => nil) do |f|
      f.each_line do |line|
        row = line.strip.split(/\t/)
        hash = {'Colony name' => row[0], 'MGI accession id' => row[1], 'Allele name' => row[2]}
        data.push hash
      end
    end

    data = data.sort { |a, b| a['Colony name'] <=> b['Colony name'] }

    data
  end

  def apply_changes data
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
    end
  end

  desc 'Load ALL JAX Phenotype Attempt changes'
  task 'load_all' => [:environment] do
    file_list = get_files
    data = []
    file_list.each do |file|
      data += read_data file
    end

    apply_changes data
  end

  desc 'Load current JAX Phenotype Attempt changes'
  task 'load_current' => [:environment] do
    data = read_data 'mgi_allele_ikmc.txt.current'
    apply_changes data
  end

  desc 'Get CSV of all changes'
  task 'get_csv' => [:environment] do
    home = Dir.home

    file_list = get_files
    data = []
    file_list.each { |file| data += read_data file }
    filename = "#{home}/JAX-#{Time.now.strftime('%Y-%m-%d')}.csv"
    puts "#### creating file '#{filename}'"
    CSV.open(filename, "wb") do |csv|
      csv << data[0].keys
      data.each do |row|
        csv << row.values
      end
    end
  end
end
