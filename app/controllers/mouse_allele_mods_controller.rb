# encoding: utf-8

class MouseAlleleModsController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def create
    @mouse_allele_mod =  Public::MouseAlleleMod.new(params[:mouse_allele_mod])
#    @phenotyping_production.updated_by = current_user
    return unless authorize_user_production_centre(@mouse_allele_mod)
    return if empty_payload?(params[:mouse_allele_mod])

    respond_with @mouse_allele_mod do |format|
      format.json do
        if @mouse_allele_mod.valid?
          @mouse_allele_mod.save
          render :json => @mouse_allele_mod
        else
          render :json => @mouse_allele_mod.errors.messages
        end
      end
    end
  end

  def update
    @mouse_allele_mod =  Public::MouseAlleleMod.find(params['id'])

    return if @mouse_allele_mod.blank?
    return unless authorize_user_production_centre(@mouse_allele_mod)
    return if empty_payload?(params[:mouse_allele_mod])

    @mouse_allele_mod.update_attributes(params[:mouse_allele_mod])

    respond_with @mouse_allele_mod do |format|
      format.json do
        if @mouse_allele_mod.valid?
          render :json => @mouse_allele_mod
        else
          render :json => @mouse_allele_mod.errors.messages
        end
      end
    end
  end

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
