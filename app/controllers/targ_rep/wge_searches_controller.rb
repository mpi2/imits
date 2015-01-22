class TargRep::WgeSearchesController < TargRep::BaseController

  respond_to :json

  def exon_search
    data = []
    all_values = []
    error = ""
    params_passed = true

    ## Check gene exists in iMits
    if params.has_key?(:marker_symbol)
      marker_symbol = params[:marker_symbol]
      if Gene.find_by_marker_symbol(marker_symbol).blank?
        marker_symbol = Gene.find(:first, :conditions => ["lower(marker_symbol) = ?", marker_symbol.downcase]).try(:marker_symbol)
      end
    end


    ## check Params
    if marker_symbol.blank?
      error = "Gene not found for this marker_symbol #{params[:marker_symbol]}"
      params_passed = false
    end


    if params_passed
      response = wge_call("api/exon_search?species=Mouse&marker_symbol=#{marker_symbol}")

      if response.message != 'Bad Request'
        JSON.parse(response.body)['exons'].each do |exon|
          data << {'exon_id' => exon['exon_id'], 'value' => exon['exon_id'], 'rank' => exon['rank']}
          all_values << exon['exon_id']
        end
        data = data.sort{|a1, b2| a1['rank'] <=> b2['rank']}
        data.insert(0, {'exon_id' =>'All', 'value' => all_values, 'rank' => 0})
      else
        error = "No exons available for the gene #{params[:marker_symbol]}"
      end
   end

    respond_to do |format|
      if error.blank?
        format.json { render :json => data.to_json}
      else
        format.json { render :json => error.to_json}
      end
    end
  end

  def crispr_search
    exon_ids = params[:exon_id]

    response = wge_call("api/crispr_search?exon_id[]=#{exon_ids.join('&exon_id[]=')}&flank=200")

    data = []

    if response.message != 'Bad Request'
      JSON.parse(response.body).each do |exon, crisprs|
        data << crisprs
      end
      data = data.flatten
      data = data.sort{|a1, b2| a1['seq'] <=> b2['seq']}
    else
      error = "No crispr available for this gene"
    end


    respond_to do |format|
      if error.blank?
        format.json { render :json => data.to_json}
      else
        format.json { render :json => error.to_json}
      end
    end
  end

  def crispr_search_by_grna_sequence
    error = ""
    seqs = params[:seq]

    data = []
    seqs.lines.each do |seq|
      seq = seq.strip
      next if seq.length != 20 or seq =~ /[^ACGTacgt]/
      response = wge_call("api/search_by_seq?seq=#{seq}&pam_right=2&get_db_data=1&species=Mouse")
      JSON.parse(response.body).each do |crispr|
        # puts "DATA: #{crispr}"
        data << {'seq' => crispr['seq'], 'chr_name' => crispr['chr_name'], 'chr_start' => crispr['chr_start'], 'chr_end' => crispr['chr_end']}
      end
    end

    respond_to do |format|
      if error.blank?
        format.json { render :json => data.to_json}
      else
        format.json { render :json => error.to_json}
      end
    end
  end


  def crispr_pair_search
    exon_ids = params[:exon_id]

    response = wge_call("api/pair_search?exon_id[]=#{exon_ids.join('&exon_id[]=')}&flank=200")

    data = []

    if response.message != 'Bad Request'
      JSON.parse(response.body).each do |exon, crisprs|
        crisprs.each do |crispr|
          data << {'right_crispr' => crispr['right_crispr']['seq'],
                   'right_crispr_chr' => crispr['right_crispr']['chr_name'],
                   'right_crispr_chr_start' => crispr['right_crispr']['chr_start'],
                   'right_crispr_chr_end' => crispr['right_crispr']['chr_end'],
                   'left_crispr' => crispr['left_crispr']['seq'],
                   'left_crispr_chr' => crispr['left_crispr']['chr_name'],
                   'left_crispr_chr_start' => crispr['left_crispr']['chr_start'],
                   'left_crispr_chr_end' => crispr['left_crispr']['chr_end']}
        end
      end
      data = data.flatten
      data = data.sort{|a1, b2| [a1['left_crispr']['seq'], a1['right_crispr']['seq']] <=> [b2['left_crispr']['seq'], b2['right_crispr']['seq']]}
    else
      error = "No crispr-pairs available for this gene"
    end


    respond_to do |format|
      if error.blank?
        format.json { render :json => data.to_json}
      else
        format.json { render :json => error.to_json}
      end
    end
  end

  def protein_translation_for_region
    species   = params[:species]
    chr_name  = params[:chr_name]
    chr_start = params[:chr_start]
    chr_end   = params[:chr_end]

    if ( species && chr_name && chr_start && chr_end )

      response = wge_call("api/translation_for_region?species=#{species}&chr_name=#{chr_name}&chr_start=#{chr_start}&chr_end=#{chr_end}")

      data = []

      if response.message != 'Bad Request'
        JSON.parse(response.body).each do |feature|
          data << feature
        end
       else
        error = "No protein translation available for this region"
      end

    else
      error = "Parameters not all present for protein translation"
    end

    respond_to do |format|
      if error.blank?
        format.json { render :json => data.to_json}
      else
        format.json { render :json => error.to_json}
      end
    end

  end

  def mutant_protein_translation_for_colony
    species    = params[:species]
    chr_name   = params[:chr_name]
    chr_start  = params[:chr_start]
    chr_end    = params[:chr_end]
    colony_id  = params[:colony_id]

    if ( species && chr_name && chr_start && chr_end && colony_id )
      response = wge_call("api/translation_for_region?species=#{species}&chr_name=#{chr_name}&chr_start=#{chr_start}&chr_end=#{chr_end}")

      wt_data = []

      if response.message != 'Bad Request'
        JSON.parse(response.body).each do |feature|
          wt_data << feature
        end

        colony = Colony.find_by_id(colony_id)
        if colony
          chr_strand = colony.mi_attempt.mi_plan.gene.strand_name

          # NB this data is an array of features each containing sequence, but NOT in any order, so we need to sort it
          # and the sort order depends on strand of the protein we are looking at
          if chr_strand == '+'
            sorted_wt_data = wt_data.sort_by { |feature| feature["start"] }
          else
            sorted_wt_data = wt_data.sort_by { |feature| feature["start"] }.reverse
          end

          mutant_seq_file = colony.trace_call.file_mutant_fa

          if mutant_seq_file

            # need to fetch mutant protein id and sequence from colony trace call
            mut_protein_id, mut_protein_seq = get_protein_details_from_mutant_fa(mutant_seq_file)

            # construct a revised feature array with modified protein sequence
            mut_data = construct_mut_protein_features(sorted_wt_data, mutant_seq_file, mut_protein_id, mut_protein_seq, chr_strand)

          else
            error = "No protein sequence file found for this colony"
          end

        else
          error = "No colony found for this id : #{colony_id}"
        end

       else
        error = "No protein translation available for this region"
      end

    else
      error = "Parameters not all present for protein translation"
    end

    respond_to do |format|
      if error.blank?
        format.json { render :json => mut_data.to_json}
      else
        format.json { render :json => error.to_json}
      end
    end

  end

private
  def wge_call(request_url_str)
    uri = URI("#{Rails.configuration.wge_root}/#{request_url_str}")

  #  puts "URL SCHEME :#{uri.scheme} HOST : #{uri.host} PATH : #{uri.path} QUERY : #{uri.query} : FRAGMENT #{uri.fragment} : STRING #{uri.to_s}"

    res = Net::HTTP.get_response(uri)
 #   puts "BODY #{res.body}"
    res
  end

  def get_protein_details_from_mutant_fa(mutant_seq_file)

    return unless mutant_seq_file

    mut_protein_id = ''
    mut_protein_seq = ''

    # e.g. file contents ">ENSMUSP00000038754.8:p.Gln32ArgfsTer14\nMADTETDQGLNKKLSFSFCEEDTESEGQMTARRGPEPKAWEGRK*\n"

    index = 0
    mutant_seq_file.each_line do |line|
      index += 1
      if index == 1
        # the first line should contain the protein id e.g. ENSMUSP00000038754
        if match = line.match(/>(\w*).*/i)
          mut_protein_id = match.captures[0]
        end
      else
        # other line(s) should contain the amino acid sequence
        mut_protein_seq << line.strip
      end
    end

    return mut_protein_id, mut_protein_seq
  end

  def construct_mut_protein_features(sorted_wt_data, mutant_seq_file, mut_protein_id, mut_protein_seq, chr_strand)

    mut_data = []
    mut_aa_index = 0
    matched_all_mut_seq_chars = false
    first_mut_feature = true

    sorted_wt_data.each do |wt_feature|

      if matched_all_mut_seq_chars
        break
      end

      # ignore unless feature for correct protein
      wt_protein_id = wt_feature['protein']

      next unless wt_protein_id == mut_protein_id

      curr_mut_feature = {
        'gene'        => wt_feature['gene'],
        'start_phase' => wt_feature['start_phase'],
        'start_index' => wt_feature['start_index'],
        'transcript'  => wt_feature['transcript'],
        'strand'      => wt_feature['strand'],
        'chr_name'    => wt_feature['chr_name'],
        'start'       => wt_feature['start'],
        'end'         => wt_feature['end'],
        'protein'     => wt_feature['protein'],
        'sequence'    => ''
      }

      wt_feature_sequence = wt_feature['sequence']

      # compare wild type and mutant sequences
      # N.B. sometimes sequences from WT exons 'miss' displaying an amino acid on the join (codon split between exons?) so
      # we allow a one amino acid slip in comparison for the first cycle only
      if first_mut_feature
        check_first_aa = false
      else
        check_first_aa = true
      end

      num_amino_acids = 0
      wt_feature_sequence.each_char do|wt_c|

        mut_c = mut_protein_seq[mut_aa_index]

        # first aa in mutant sequence may be 'missing' from start of wt sequence (codon split between exons)
        if check_first_aa
          if ( mut_protein_seq.length > ( mut_aa_index + 3 ) && wt_feature_sequence.length >= 3 )
            # if skip one aa then next 3 aa's match add aa to mut sequence
            if ( mut_protein_seq[(mut_aa_index + 1)..(mut_aa_index + 3)] == wt_feature_sequence[0..2] )
              curr_mut_feature['sequence'] << mut_c
              mut_aa_index += 1
              num_amino_acids += 1
              mut_c = mut_protein_seq[mut_aa_index]
              # also need to modify 'start' or 'end' location
              if chr_strand == '+'
                # start is a codon earlier, 3 nucleotides
                curr_mut_feature['start'] = curr_mut_feature['start'] - 3
              else
                # end is a codon earlier, 3 nucleotides
                curr_mut_feature['end'] = curr_mut_feature['end'] + 3
              end
              curr_mut_feature['start_index'] = curr_mut_feature['start_index'] - 1
            end

          end
          check_first_aa = false
        end

        if wt_c == mut_c
          curr_mut_feature['sequence'] << mut_c
          mut_aa_index += 1
          num_amino_acids += 1
        else
          # as soon as the protein sequences fail to match, we know we are at the modification point
          # so the remaining mutant sequence goes in this feature
          curr_mut_feature['sequence'] << mut_protein_seq[mut_aa_index..-1]
          num_amino_acids += mut_protein_seq.length - mut_aa_index

          # NB need to adjust the 'end' of this feature (or the 'start' for -ve strand proteins)
          num_aa = curr_mut_feature['sequence'].length
          num_nuc = num_aa * 3
          if chr_strand == '+'
            # start stays the same, end is start + sequence length * 3 - 1
            f_start = curr_mut_feature['start']
            curr_mut_feature['end'] = f_start + num_nuc - 1
          else
            # end stays the same, start is end - sequence length * 3 + 1
            f_end = curr_mut_feature['end']
            curr_mut_feature['start'] = f_end - num_nuc + 1
          end

          matched_all_mut_seq_chars = true
          break
        end
      end

      curr_mut_feature['num_amino_acids'] = num_amino_acids

      mut_data.push(curr_mut_feature)
      first_mut_feature = false

    end

    return mut_data
  end

end
