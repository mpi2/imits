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
    Colony.transaction do
      data.each do |row|
        clean_name = row['Colony name'].gsub("&lt;", '<').gsub("&gt;", '>')
        col = Colony.find_by_name clean_name
        log "cannot find '#{row['Colony name']}' - #{row.to_s}" if ! col
        failures += 1 if ! col
        next if ! col
        before = "#{col.id}; #{col.name}; #{col.mgi_allele_id}; #{col.allele_name}"

        if DIFF
          diff = col.mgi_allele_id != row['MGI accession id'] || col.allele_name != row['Allele name']
          next if ! diff
          diffed += 1
        end

        col.allele_name = row['Allele name']
        col.mgi_allele_id = row['MGI accession id']
        col.save!
        col.reload
        after = "#{col.id}; #{col.name}; #{col.mgi_allele_id}; #{col.allele_name}"
        log "before: #{before} - after: #{after}"
      end
      puts  "#### results: #{failures}/#{diffed}/#{data.size}"
    end
  end

  desc 'Load ALL JAX Mouse Allele changes'
  task 'load_all' => [:environment] do
    file_list = get_files
    data = []
    file_list.each do |file|
      data += read_data file
    end

    apply_changes data
  end

  desc 'Load current JAX Mouse Allele Mod changes'
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
