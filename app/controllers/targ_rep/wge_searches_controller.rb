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
        puts "DATA: #{crispr}"
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

    response = wge_call("api/translation_for_region?species=#{species}&chr_name=#{chr_name}&chr_start=#{chr_start}&chr_end=#{chr_end}")

    data = []

    if response.message != 'Bad Request'
      JSON.parse(response.body).each do |feature|
        require 'pp'
        pp feature
        # data << {'seq' => crispr['seq'], 'chr_name' => crispr['chr_name'], 'chr_start' => crispr['chr_start'], 'chr_end' => crispr['chr_end']}

        data << feature
        # {
        #   "start_phase"=>"-1",
        #   "sequence"=>"???",
        #   "nucleotides"=>"???",
        #   "gene"=>"ENSMUSG00000037172",
        #   "start_index"=>1,
        #   "transcript"=>"ENSMUST00000039008",
        #   "end_base"=>nil,
        #   "strand"=>"-1",
        #   "id"=>"ENSMUSE00000341663",
        #   "chr_name"=>"6",
        #   "start_base"=>{"len"=>"1", "codon"=>"GGA", "aa"=>"G"},
        #   "end"=>40436125,
        #   "protein"=>"ENSMUSP00000045103",
        #   "num_amino_acids"=>89,
        #   "end_phase"=>"1",
        #   "rank"=>1,
        #   "start"=>40435859
        # }

      end
     else
      error = "No protein translation available for this region"
    end

    respond_to do |format|
      if error.blank?
        format.json { render :json => data.to_json}
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
end
