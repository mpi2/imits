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
    if params[:clone_name].blank?
      respond_with []
    else
      respond_with Clone.mart_search_by_clone_names( [ params[:clone_name] ] )
    end
  end

end
