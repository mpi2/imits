class EsCellQcUpload
  # QC Type, Primary(WTSI ES Cell production), Seondary (Distribution Centre) or Tertiary (Production Centre/Mouse Clinic)


  # Params provided QC Type, Centre Name, File
  QC_TYPES = {'Primary' => 'WTSI ES Cell production',
              'Secondary' => 'Distribution Centre',
              'Tertiary' => 'Production Centre/Mouse Clinic'}

  CENTRES_WITH_UPLOAD_PROFILES = ['TCP', 'UCD', 'JAX', 'Harwell']

  USER_QC_FIELDS = ['user_qc_map_test',
                    'user_qc_karyotype',
                    'user_qc_tv_backbone_assay',
                    'user_qc_loxp_confirmation',
                    'user_qc_southern_blot',
                    'user_qc_loss_of_wt_allele',
                    'user_qc_neo_count_qpcr',
                    'user_qc_lacz_sr_pcr',
                    'user_qc_mutant_specific_sr_pcr',
                    'user_qc_five_prime_cassette_integrity',
                    'user_qc_neo_sr_pcr',
                    'user_qc_five_prime_lr_pcr',
                    'user_qc_three_prime_lr_pcr',
                    'user_qc_comment',
                    'user_qc_loxp_srpcr_and_sequencing',
                    'user_qc_karyotype_spread',
                    'user_qc_karyotype_pcr',
                    'user_qc_chr1',
                    'user_qc_chr11',
                    'user_qc_chr8',
                    'user_qc_chry',
                    'user_qc_lacz_qpcr'
                   ]

  def initialize(qc_type, centre_name, filename)
    raise "ERROR: QC Type missing or unrecognized. Accepted values #{QC_TYPES.keys.to_sentence}" unless QC_TYPES.has_key?(qc_type)
    raise "ERROR: Please provide a valid Centre Name" unless Centre.find_by_name(centre_name) && CENTRES_WITH_UPLOAD_PROFILES.include?(centre_name)
    raise "ERROR: File not found" if filename.blank? && !does_file_exist?(filename)

    @extra_columns = []
    @data = []
    @errors = {}

    if qc_type == 'Tertiary'
      if centre_name == 'TCP'
        process_tcp_file(filename)
      elsif centre_name == 'UCD'
        process_komp_file(filename)
      elsif centre_name == 'JAX'
        process_jax_file(filename)
      elsif centre_name == 'Harwell'
        process_harwell_file(filename)
      end
    end
  end

  def data
    return @data
  end

  def extra_columns
    return @extra_columns
  end


  def does_file_exist?(filename)
    if File.file?(filename) && filename =~ /.csv/
      return true
    end
    return false
  end



  def upload_qc_results(centre_name)

    centre = Centre.find_by_name(centre_name)

    if centre.blank?
      add_error('invalid centre' , centre_name)
      return
    end

    i=0
    @data.each do |clone, row|
      i +=1
      if clone.blank?
        add_error('no es_cell_name' , i)
        next
      end

      # find clone
      c = TargRep::EsCell.where("LOWER(name) = '#{clone}'").first

      if c.blank?
        add_error('es_cell_name not in TargRep' , clone)
        next
      end

      es = TargRep::EsCell.find(c.id)

      #Has QC been entered by a different Centre or is this additional QC.
      if row.has_key?('additional_qc') && row['additional_qc'] = true
        centre_name = es.user_qc_mouse_clinic.try(:name)
      elsif !es.user_qc_mouse_clinic_id.blank? && es.user_qc_mouse_clinic_id != centre.id &&
        add_error('centre mismatch' , [clone, es.user_qc_mouse_clinic.name, centre_name])
        next
      end

      #Is there existing QC
      USER_QC_FIELDS.each do |field|
        unless es.send(field).blank?
          unless row.has_key?('additional_qc') && row['additional_qc'] = true
            add_error('existing data' , [clone, es.dup, row.dup])
            break
          end
        end
      end

      #update models attributes and check for changes.
      USER_QC_FIELDS.each do |field|
        if row.has_key?(field)
          es.send("#{field}=", row[field])
        end
      end

      if es.changed?
        add_error('changed' , [clone, es.changes])
      else
        add_error('No Data' , [clone, row])
      end
    end
  end

  def add_error(message, data)
    @errors[message] = [] unless @errors.has_key?(message)
    @errors[message] << data
  end

  def errors
    return @errors
  end


  def process_jax_file(filename)
    data_hash = {}
    columns = { "es cell jr#"                                               => 0,
                "marker"                                                   => 1,
                "clone id"                                                 => 2,
                "date delivered dna"                                       => 3,
                "priority"                                                 => 4,
                "chromosome count (%)"                                     => 5,
                "date received"                                            => 6,
                "vlcg (regeneron) or csd (es+2i)"                          => 7,
                "mgi clone id"                                             => 8,
                "cell line"                                                => 9,
                "neo count (p=pending f=fail a=acceptable)"              => 10,
                "loa assay (p=pending f=fail a=acceptable)"              => 11,
                "3' distal loxp assay"                                     => 12,
                "loa design assay"                                         => 13,
                "fpvi"                                                     => 14,
                "mb qc passed/proceed to mij (rick or leslie to complete)" => 15,
                "action completed (entered by cell bio only)"              => 16
               }

    columns_mapping = { "mgi clone id"                                             => 'es_cell_name',
                        "neo count (p=pending f=fail a=acceptable)"              => 'user_qc_neo_count_qpcr',
                        "loa assay (p=pending f=fail a=acceptable)"              => 'user_qc_loss_of_wt_allele',
                        "3' distal loxp assay"                                     => 'user_qc_loxp_confirmation',
            #            "fpvi"                                                     => '' ??????
                       }

    # open file
    file = File.open(filename)
    headers = convert_row_to_array(file.readline().gsub('\n',''))
    columns = check_column_header_mapping(headers, columns)

    puts @extra_columns

    until file.eof()
      line = convert_row_to_array(file.readline().gsub('\n',''))
      next if line[columns["mgi clone id"]].blank?

      data_hash[ line[columns["mgi clone id"]] ] = {}

      columns_mapping.each do |column_name, value|
        next if columns_mapping[column_name] !~ /user_qc/
        next if line[columns[column_name]].blank?
        next if line[columns[column_name]] =~ /n\/a/
        next if line[columns[column_name]] == 'no assay possible'

        if line[columns[column_name]] =~ /a/
          data_hash[ line[columns["mgi clone id"]] ][value] = 'pass'
        elsif line[columns[column_name]] =~ /f/
          data_hash[ line[columns["mgi clone id"]] ][value] = 'fail'
        end
      end

      next if data_hash[ line[columns["mgi clone id"]]].keys.count == 0

      data_hash[ line[columns["mgi clone id"]] ] ['status'] = ''
      if !line[columns["mb qc passed/proceed to mij (rick or leslie to complete)"]].blank? && line[columns["mb qc passed/proceed to mij (rick or leslie to complete)"]] !~ /hold/
        if line[columns["mb qc passed/proceed to mij (rick or leslie to complete)"]] =~ /failed/
          data_hash[ line[columns["mgi clone id"]] ] ['status'] = 'fail'
        else
          data_hash[ line[columns["mgi clone id"]] ] ['status'] = 'pass'
        end
      end
    end

    @data = data_hash.dup
  end



  def process_harwell_file(filename)
    data_hash = {}
    columns = { "marker symbol"          => 0,
                "ref clone"              => 1,
                "loxp"                   => 2,
                "southern neo"           => 3,
                "cnv ddpcr chr8"         => 4,
                "cnv sspcr chry"         => 5,
                "karyotype by spreading" => 6,
                "mixed clones clone"     => 7,
                "comments karyotype"     => 8
               }

    columns_mapping = { "ref clone"                 => 'es_cell_name',
                        "loxp"                      => 'user_qc_loxp_confirmation',
                        "southern neo"              => 'user_qc_southern_blot',
                        "cnv ddpcr chr8"            => 'user_qc_chr8',
                        "cnv sspcr chry"            => 'user_qc_chry',
                        "karyotype by spreading"    => 'user_qc_karyotype_spread'
                       }

    # open file
    file = File.open(filename)
    headers = convert_row_to_array(file.readline().gsub('\n',''))
    columns = check_column_header_mapping(headers, columns)

    puts @extra_columns

    until file.eof()
      line = convert_row_to_array(file.readline().gsub('\n',''))
      next if line[columns["ref clone"]].blank?

      data_hash[ line[columns["ref clone"]] ] = {}
      status = true
      columns_mapping.each do |column_name, value|

        next if columns_mapping[column_name] !~ /user_qc/

        if line[columns[column_name]] =~ /no/ || line[columns[column_name]] =~ /negative/  || line[columns[column_name]] =~ /abnormal/
          data_hash[ line[columns["ref clone"]] ][value] = 'fail'
        elsif line[columns[column_name]] =~ /yes/ || line[columns[column_name]] =~ /positive/ || line[columns[column_name]] =~ /normal/
          data_hash[ line[columns["ref clone"]] ][value] = 'pass'
        elsif line[columns[column_name]] =~ /limite/
          data_hash[ line[columns["ref clone"]] ][value] = 'limit'
        end
        if data_hash[ line[columns["ref clone"]] ][value] == 'fail'
          status = false
        end
      end

      data_hash[ line[columns["ref clone"]] ] ['status'] = status
    end

    @data = data_hash.dup
  end


  def process_tcp_file(filename)
    data_hash = {}
    columns = {"clone id"      => 0,
                "%euploid"      => 1,
                "final status"  => 2,
                "repository"    => 3,
                "chr1 qpcr"     => 4,
                "chr11 qpcr"    => 5,
                "chr8 qpcr"     => 6,
                "chry qpcr"     => 7,
                "lacz qpcr"     => 8,
                "loa wi allele" => 9,
                "5lr-pcr"       => 10,
                "3pr-pcr"       => 11,
                "neo qpcr"      => 12,
                "3' southern"   => 13,
                "5' southern"   => 14
               }

    columns_mapping = { "clone id"      => 'es_cell_name',
                        "chr1 qpcr"     => 'user_qc_chr1',
                        "chr11 qpcr"    => 'user_qc_chr11',
                        "chr8 qpcr"     => 'user_qc_chr8',
                        "chry qpcr"     => 'user_qc_chry',
                        "lacz qpcr"     => 'user_qc_lacz_qpcr',
                        "loa wi allele" => 'user_qc_loss_of_wt_allele',
                        "5lr-pcr"       => 'user_qc_five_prime_lr_pcr',
                        "3pr-pcr"       => 'user_qc_three_prime_lr_pcr',
                        "neo qpcr"      => 'user_qc_neo_count_qpcr'
                       }

    # open file
    file = File.open(filename)
    headers = convert_row_to_array(file.readline().gsub('\n',''))
    columns = check_column_header_mapping(headers, columns)

    puts @extra_columns

    until file.eof()
      line = convert_row_to_array(file.readline().gsub('\n',''))
      next if line[columns["clone id"]].blank?

      data_hash[ line[columns["clone id"]] ] = {}

      three_southern = line[columns["3' southern"]]
      five_southern = line[columns["5' southern"]]

      unless three_southern.blank? && five_southern.blank?
         if (three_southern == 'fail' or five_southern == 'fail')
           data_hash[ line[columns["clone id"]] ] ['southern'] = 'fail both ends'
         elsif three_southern == 'fail'
           data_hash[ line[columns["clone id"]] ] ['southern'] = "fail 3' end"
         elsif five_southern == 'fail'
           data_hash[ line[columns["clone id"]] ] ['southern'] = "fail 5' end"
         elsif (three_southern =~ /pass/ or five_southern =~ /pass/)
           data_hash[ line[columns["clone id"]] ] ['southern'] = 'pass'
         end
      end

      data_hash[ line[columns["clone id"]] ] ['additional_qc'] = 'false'
      if line[columns["final status"]] == 'passk'
        data_hash[ line[columns["clone id"]] ] ['additional_qc'] = 'true'
      elsif line[columns["final status"]] == 'fail'
        data_hash[ line[columns["clone id"]] ] ['status'] = 'fail'
      else
        data_hash[ line[columns["clone id"]] ] ['status'] = 'pass'
      end
      ## NOTE IF PASSK ADD TO UCD QC AND ADD COMMENT SAYING WHICH TEST WHERE CARRIED OUT BY TCP.
      columns_mapping.each do |column_name, value|
        next if columns_mapping[column_name] !~ /user_qc/ || ! TargRep::EsCell.qc_options[columns_mapping[column_name]][:values].include?(line[columns[column_name]])
        data_hash[ line[columns["clone id"]] ][value] = line[columns[column_name]] unless line[columns[column_name]].blank?
      end
    end

    @data = data_hash.dup
  end

  def process_komp_file(filename)
    data_hash = {}
    columns = { "project status"     => 0,
                "gene"               => 1,
                "clone id"           => 2,
                "origin"             => 3,
                "project id"         => 4,
                "mutation"           => 5,
                "growth"             => 6,
                "genotype"           => 7,
                "pathogen"           => 8,
                "chromosome count"   => 9,
                "tmk"                => 10
               }

    qc_mapping = {"knockout first" => {
                                     "user_qc_loxp_confirmation" => "pass",
                                     "user_qc_copy_number"       => "pass",
                                     "user_qc_chry"              => "pass",
                                     "user_qc_five_prime_lr_pcr" => "pass",
                                     "user_qc_vector_integrity"  => "pass",
                                     "user_qc_genome_integrity"  => "pass"
                                     },
                "targeted non-conditional" => {
                                     "user_qc_copy_number"       => "pass",
                                     "user_qc_chry"              => "pass",
                                     "user_qc_five_prime_lr_pcr" => "pass",
                                     "user_qc_vector_integrity"  => "pass",
                                     "user_qc_genome_integrity"  => "pass"
                                     },
                "csd deletion" => {
                                     "user_qc_copy_number"       => "pass",
                                     "user_qc_chry"              => "pass",
                                     "user_qc_five_prime_lr_pcr" => "pass",
                                     "user_qc_vector_integrity"  => "pass",
                                     "user_qc_genome_integrity"  => "pass"
                                     },
                "vg deletion" => {
                                     "user_qc_copy_number"       => "pass",
                                     "user_qc_loxp_confirmation" => "pass",
                                     "user_qc_chry"              => "pass",
                                     "user_qc_5_prime_junction"  => "pass"
                                     },
                  "gene trap" =>  {
                                     "user_qc_copy_number"       => "pass",
                                     "user_qc_5_prime_junction"  => "pass"
                                  }

                }

    # open file
    file = File.open(filename)
    headers = convert_row_to_array(file.readline().gsub('\n',''))
    columns = check_column_header_mapping(headers, columns)

    puts @extra_columns

    until file.eof()
      line = convert_row_to_array(file.readline().gsub('\n',''))
      next if line[columns["clone id"]].blank?

      mutation_type = line[columns["mutation"]]

      next if ['insertion', 'gene trap', 'creed deletion'].include?(mutation_type)

      if line[columns["mutation"]] ==  "deletion"
        if line[columns["project id"]] =~ /VG/
          mutation_type = "vg deletion"
        else
          mutation_type = "csd deletion"
        end
      end

      next if mutation_type.blank? or !["knockout first", "targeted non-conditional", "csd deletion", "vg deletion"].include?(mutation_type)


      data_hash[ line[columns["clone id"]] ] = {}
      data_hash[ line[columns["clone id"]] ]["mutation_type"] = mutation_type

      if line[columns["genotype"]] == 'pass'
        qc_mapping[mutation_type].each do |column, value|
          data_hash[ line[columns["clone id"]] ][column] = value
        end
        data_hash[ line[columns["clone id"]] ] ['status'] = 'pass'
      else
        data_hash[ line[columns["clone id"]] ] ['status'] = 'fail'
      end

    end

    @data = data_hash.dup
  end

  def check_column_header_mapping(headers, columns)
    (0..headers.length-1).to_a.each do |i|
      unless columns.has_key?(headers[i])
        @extra_columns << headers[i]
        next
      end

      if columns[headers[i]] != i
        columns[headers[i]] = i
      end
    end

    return columns
  end

  def convert_row_to_array(row)
    row = row.gsub(/Targeted\, non-conditional/, 'Targeted non-conditional')
    return row.split(',').map{|column| column.strip().gsub(/\"/, '').downcase}
  end

end