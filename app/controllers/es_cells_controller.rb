# encoding: utf-8

class EsCellsController < ApplicationController

  respond_to :xml, :json

  before_filter :authenticate_user!

  def mart_search
    if ! params[:es_cell_name].blank?
      respond_with TargRep::EsCell.where('lower(name) like ?', "%#{params[:es_cell_name].to_s.downcase}%"),
        :methods => ['marker_symbol', 'pipeline_name']

    elsif ! params[:marker_symbol].blank?
      respond_with TargRep::EsCell.includes(:allele => [:gene]).where('lower(genes.marker_symbol) = ?', params[:marker_symbol].to_s.downcase),
        :methods => ['marker_symbol', 'pipeline_name']
    
    else
      respond_with []
    end
  end

end
