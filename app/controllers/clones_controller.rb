# encoding: utf-8

class ClonesController < ApplicationController

  respond_to :xml, :json

  before_filter :authenticate_user!

  def show
    @clone = Clone.find(params[:id])
    respond_with @clone
  end

  def index
    @clones = Clone.search(cleaned_params).all
    respond_with @clones
  end

  def mart_search
    if ! params[:clone_name].blank?
      respond_with Clone.get_clones_from_marts_by_clone_names( [ params[:clone_name] ] )
    elsif ! params[:marker_symbol].blank?
      respond_with Clone.get_clones_from_marts_by_marker_symbol( params[:marker_symbol] )
    else
      respond_with []
    end
  end

end
