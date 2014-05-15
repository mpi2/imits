# encoding: utf-8

class MouseAlleleModsController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def show
    @mouse_allele_mod = Public::MouseAlleleMod.find(params[:id])
    respond_with @mouse_allele_mod do |format|
      format.json do
        render :json => @mouse_allele_mod
      end
    end
  end

  def colony_name
    @mouse_allele_mod = Public::MouseAlleleMod.find_by_colony_name(params[:colony_name])
    respond_with @mouse_allele_mod do |format|
      format.json do
        render :json => @mouse_allele_mod
      end
    end
  end

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'id asc', Public::MouseAlleleMod, :public_search, false)
      end
    end
  end
end
