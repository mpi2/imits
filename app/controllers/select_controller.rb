class SelectController < ApplicationController

  respond_to :json

  def vector
    marker_symbol = params[:marker_symbol]

    tvs = !marker_symbol.blank? ? TargRep::TargetingVector.joins(allele: :gene).where("UPPER(genes.marker_symbol) = '#{marker_symbol.upcase}'") : []

    seralised_hash = {'es_cell' => {'targeting_vector' => []}, 'crispr' => {'targeting_vector' => []}}

    tvs.each do |tv|
      if tv.allele.type =='TargRep::CrisprTargetedAllele'
        seralised_hash['crispr']['targeting_vector'] << tv.name
      elsif tv.allele.type =='TargRep::TargetedAllele'
        seralised_hash['es_cell']['targeting_vector'] << tv.name
      end
    end

    respond_to do |format|
        format.json { render :json => seralised_hash.as_json}
    end
  end
end
