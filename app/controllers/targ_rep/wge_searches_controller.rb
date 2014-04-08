class TargRep::WgeSearchesController < TargRep::BaseController

  respond_to :json

  before_filter :authorize_admin_user!

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
        response['exons'].each do |exon|
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

    response = wge_call("api/crispr_search?exon_id[]=#{exon_ids.join('&exon_id[]=')}")

    data = []

    if response.message != 'Bad Request'
      response.each do |exon, crisprs|
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


  def crispr_pair_search
    exon_ids = params[:exon_id]

    response = wge_call("api/pair_search?exon_id[]=#{exon_ids.join('&exon_id[]=')}")

    data = []

    if response.message != 'Bad Request'
      response.each do |exon, crisprs|
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


private
  def wge_call(request_url_str)
    HTTParty.get("http://www.sanger.ac.uk/htgt/wge/#{request_url_str}")
  end
end
