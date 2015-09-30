#!/usr/bin/env ruby

require 'open-uri'
require 'net/ftp'

class MgiAlleleNameUpdate

  DIFF = false
  VERBOSE = true
  URL_ROOT = 'ftp.informatics.jax.org'
  URL_PUBLIC_FOLDER = 'pub'
  URL_TARGET = "ftp://#{URL_ROOT}/#{URL_PUBLIC_FOLDER}/"

  PRODUCT_TO_FILE_NAMES = {'es_cells' => {'files' => ['reports/KOMP_Allele.rpt', 'reports/NorCOMM_Allele.rpt', 'reports/EUCOMM_Allele.rpt'], 'download_template' => 'es_cell_allele_download_template'},
                           'derived_mice' => {'files' => ['IKMC/'], 'download_template' => 'derived_allele_download_template'},
                           'cirspr_mice' => {'files' => [], 'download_template' => 'crispr_allele_download_template'}
                          }


  def es_cell_update
    mgi_allele_data = get_mgi_data('es_cells')

    targ_rep_es_cells = TargRep::EsCell.all

    targ_rep_es_cells.each do |es_cell|
      mgi_allele = mgi_allele_data[es_cell.name]

      if mgi_allele.blank?
        log "NOTE: MGI missing allele for #{es_cell.name}"
        next
      end

      log "#{mgi_allele['mgi_allele_id']} #{mgi_allele['mgi_allele_name']} : #{es_cell.mgi_allele_id} #{es_cell.mgi_allele_symbol_superscript}"
      if !mgi_allele['mgi_allele_id'].blank? && !mgi_allele['mgi_allele_name'].blank? && (mgi_allele['mgi_allele_id'] != es_cell.mgi_allele_id || mgi_allele['mgi_allele_name'] != es_cell.mgi_allele_symbol_superscript)
        updated = update_es_cell(es_cell.id, mgi_allele)

        log "ERROR: ES Cell failed to update MGI allele ID: #{es_cell.mgi_allele_id} => #{mgi_allele['mgi_allele_id']}; MGI Allele Name: #{es_cell.mgi_allele_symbol_superscript} => #{mgi_allele['mgi_allele_name']};" unless updated
      end
    end
    nil
  end

  def update_es_cell(es_cell_id, allele)
    es_cell = TargRep::EsCell.find(es_cell_id)

    if ! es_cell
      log "ERROR: cannot find ES Cell with id'#{es_cell_id}}"
      return false
    end

    es_cell.mgi_allele_symbol_superscript = allele['mgi_allele_name']
    es_cell.mgi_allele_id = allele['mgi_allele_id']

    if es_cell.valid?
      es_cell.save
      log "SUCESSFUL: ES CELL UPDATE #{es_cell.name}"
      return true
    else
      log "ERROR: Failed to save because es_cell failed save validation"
      return false
    end
  end

  def derived_mice_update
    mgi_allele_data = get_mgi_data('derived_mice')

    puts "Derived Allele Updates"
    derived_colonies = Colony.where("mouse_allele_mod_id IS NOT NULL AND genotype_confirmed = true")

    derived_colonies.each do |colony|
      mgi_allele = mgi_allele_data[colony.name]

      if mgi_allele.blank?
        log "NOTE: MGI missing allele for #{colony.name}"
        next
      end

      if !mgi_allele['mgi_allele_id'].blank? && !mgi_allele['mgi_allele_name'].blank? && (mgi_allele['mgi_allele_id'] != colony.mgi_allele_id || mgi_allele['mgi_allele_name'] != colony.mgi_allele_symbol_superscript)
        updated = update_derived_mice(colony.id, mgi_allele)

        log "ERROR: ES Cell failed to update MGI allele ID: #{colony.mgi_allele_id} => #{mgi_allele['mgi_allele_id']}; MGI Allele Name: #{colony.mgi_allele_symbol_superscript} => #{mgi_allele['mgi_allele_name']};" unless updated
      else
        log "Already up to date for colony #{colony.name}"
      end

    end
    nil
  end

  def update_derived_mice(colony_id, allele)
    colony = Colony.find(colony_id)

    if ! colony
      log "cannot find Colony with id'#{colony_id}}" if ! colony
      return false
    end

    colony.mgi_allele_symbol_superscript = allele['mgi_allele_name']
    colony.mgi_allele_id = allele['mgi_allele_id']

    if colony.valid?
      colony.save
      return true
    else
      return false
    end
  end

  def get_mgi_data(type)
    raise "No Files Configured to download" unless PRODUCT_TO_FILE_NAMES.key?(type)

    mgi_allele_data = {}
    files = PRODUCT_TO_FILE_NAMES[type]['files']

    files.each do |file|

      if file.last == '/'
        location = file
        files = get_files(location)
        # download all files in folder

        files.each do |mgi_file|
          read_data(type, mgi_file, mgi_allele_data)
        end
      else
        # download file
        read_data(type, file, mgi_allele_data)
      end
    end
    return mgi_allele_data
  end
#  private :get_mgi_data

  def get_files(location)
    file_list = []

    ftp = Net::FTP.new(URL_ROOT)
    ftp.login
    files = ftp.chdir("#{URL_PUBLIC_FOLDER}/#{location}")
    files = ftp.list()

    ftp.close

    files.map{|file| "#{location}#{file.split(" ").last}"}
  end

  def read_data (type, filename, hash)
    puts "FILENAME: #{filename}"
    open(URL_TARGET + filename, :proxy => nil) do |f|
      f.each_line do |line|
        next if line[0] == '#' || line.strip().length() == 0
        row = line.strip.split("\t")
        self.send(PRODUCT_TO_FILE_NAMES[type]['download_template'], hash, row)
      end
    end

    nil
  end

  def derived_allele_download_template(hash, row)
    allele_name = row[2]
    hash[row[0]] = {'colony_name' => row[0], 'mgi_allele_id' => row[1], 'mgi_allele_name' => allele_name}
    nil
  end

  def es_cell_allele_download_template(hash, row)
    return nil if row[7].blank?
    row[7].split(',').each do |es_cell_name|
      allele_name = row[3].match(/<(.*)>/)[1]
      hash[es_cell_name] = {'es_cell_name' => es_cell_name, 'MGI accession id' => row[5],'Marker Symbol' => row[6], 'mgi_allele_name' => allele_name, 'mgi_allele_id' => row[2]}
    end
    nil
  end

  def crispr_allele_download_template(hash, row)
    allele_name = row[2]
    hash[row[0]] = {'colony_name' => row[0], 'mgi_allele_id' => row[1], 'mgi_allele_name' => allele_name}
    nil
  end


  def log(message)
    puts "#### " + message.to_s if VERBOSE
  end

end
