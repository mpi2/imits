# encoding: utf-8

class EsCellsController < ApplicationController

  respond_to :xml, :json

  before_filter :authenticate_user!

  def show
    @es_cell = EsCell.find(params[:id])
    respond_with @es_cell
  end

  def index
    @es_cells = EsCell.search(cleaned_params).all
    respond_with @es_cells
  end

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
