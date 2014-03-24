require 'pp'
require 'open-uri'
require 'net/ftp'

#Rails.logger.level = 0
#@logger=Rails.logger

namespace :jax_phenotypes do

  DIFF = false
  VERBOSE = false

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

    #pp file_list

    #exit

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

    #  data = data.sort { |a, b| a['Colony name'] <=> b['Colony name'] }

    data
  end

  def log(message)
    #Rails.logger.info "#### " + message.to_s
    puts "#### " + message.to_s if VERBOSE
  end

  def apply_changes data
    failures = 0
    diffed = 0
    PhenotypeAttempt.transaction do
      data.each do |row|
        clean_name = row['Colony name'].gsub("&lt;", '<').gsub("&gt;", '>')
        pa = PhenotypeAttempt.find_by_colony_name clean_name
        log "cannot find '#{row['Colony name']}' - #{row.to_s}" if ! pa
        failures += 1 if ! pa
        next if ! pa
        before = "#{pa.id}; #{pa.colony_name}; #{pa.jax_mgi_accession_id}; #{pa.allele_name}"

        if DIFF
          diff = pa.jax_mgi_accession_id != row['MGI accession id'] || pa.allele_name != row['Allele name']

          #puts "#### '#{clean_name}'"
          #puts "#### '#{pa.jax_mgi_accession_id}' - '#{row['MGI accession id']}'"
          #puts "#### '#{pa.allele_name}' - '#{row['Allele name']}'"

          # exit

          next if ! diff

          diffed += 1
        end

        pa.allele_name = row['Allele name']
        pa.jax_mgi_accession_id = row['MGI accession id']
        pa.save!
        pa.reload
        after = "#{pa.id}; #{pa.colony_name}; #{pa.jax_mgi_accession_id}; #{pa.allele_name}"
        log "before: #{before} - after: #{after}"
      end
      puts  "#### results: #{failures}/#{diffed}/#{data.size}"
      #log "results: #{failures}/#{data.size}"
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
    log "creating file '#{filename}'"
    CSV.open(filename, "wb") do |csv|
      csv << data[0].keys
      data.each do |row|
        csv << row.values
      end
    end
  end

  #desc 'check spaces'
  #task 'check_spaces' => [:environment] do
  #  home = Dir.home
  #
  #  file_list = get_files
  #  data = []
  #  file_list.each { |file| data += read_data file }
  #
  #  data.each do |row|
  #    puts "#### spaces: #{row}" if row['Colony name'] =~ /^\s+.+/ || row['Colony name'] =~ /.+?\s+$/ || row['Colony name'] =~ /\s\s/
  #    puts "#### spaces: #{row}" if row['MGI accession id'] =~ /^\s+.+/ || row['MGI accession id'] =~ /.+?\s+$/ || row['MGI accession id'] =~ /\s\s/
  #    puts "#### spaces: #{row}" if row['Allele name'] =~ /^\s+.+/ || row['Allele name'] =~ /.+?\s+$/ || row['Allele name'] =~ /\s\s/
  #  end
  #end
end
