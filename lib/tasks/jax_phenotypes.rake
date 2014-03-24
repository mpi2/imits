require 'pp'
require 'open-uri'
require 'net/ftp'

namespace :jax_phenotypes do

  DIFF = false
  VERBOSE = false
  URL_ROOT = 'ftp.informatics.jax.org'
  URL_FOLDER = 'pub/IKMC/'
  URL_TARGET = "ftp://#{URL_ROOT}/#{URL_FOLDER}"

  #def _get_files
  #  try_count = 0
  #  begin
  #    _get_files
  #  rescue => e
  #    sleep 5
  #    try_count += 1
  #    retry if try_count < 3
  #  end
  #end

  def get_files
    file_list = []

    ftp = Net::FTP.new(URL_ROOT)
    ftp.login
    files = ftp.chdir(URL_FOLDER)
    files = ftp.list()

    files.each do |file|
      file_list.push file.scan(/(mgi_allele_ikmc.+)/).last.first if file !~ /current/
    end

    ftp.close

    file_list
  end

  def read_data filename
    #pp filename
    #pp URL_TARGET + filename
    #exit

    data = []
    open(URL_TARGET + filename, :proxy => nil) do |f|
      f.each_line do |line|
        row = line.strip.split(/\t/)
        hash = {'Colony name' => row[0], 'MGI accession id' => row[1], 'Allele name' => row[2]}
        data.push hash
      end
    end

    data
  end

  def log(message)
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
end
