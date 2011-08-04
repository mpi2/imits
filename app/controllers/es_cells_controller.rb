# encoding: utf-8

class EsCellsController < ApplicationController

  respond_to :xml, :json

  before_filter :authenticate_user!

  def mart_search
    if ! params[:es_cell_name].blank?
      respond_with EsCell.get_es_cells_from_marts_by_names( [ params[:es_cell_name] ] )
    elsif ! params[:marker_symbol].blank?
      respond_with EsCell.get_es_cells_from_marts_by_marker_symbol( params[:marker_symbol] )
    else
      respond_with []
    end
  end

end
