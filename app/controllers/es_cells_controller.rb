# encoding: utf-8

class EsCellsController < ApplicationController

  respond_to :xml, :json

  before_filter :authenticate_user!

  def mart_search
    if ! params[:es_cell_name].blank?
      respond_with TargRep::EsCell.search(:name_cont => params[:es_cell_name]).result.limit(100),
        :methods => ['marker_symbol', 'pipeline_name']

    elsif ! params[:marker_symbol].blank?
      respond_with TargRep::EsCell.search(:allele_gene_marker_symbol_cont =>  params[:marker_symbol]).result.limit(100),
        :methods => ['marker_symbol', 'pipeline_name']
    
    else
      respond_with []
    end
  end

end
