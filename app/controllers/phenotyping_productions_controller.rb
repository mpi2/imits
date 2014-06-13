# encoding: utf-8

class PhenotypingProductionsController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def create
    @phenotyping_production =  Public::PhenotypingProduction.new
    @mouse_allele_mod = Public::MouseAlleleMod.find(params['phenotyping_production']['mouse_allele_mod_id'])

    return if @mouse_allele_mod.blank?
    params[:phenotyping_production][:phenotype_attempt_id] = @mouse_allele_mod.phenotype_attempt_id

    # update through phenotype_attempt. This ensures pheotype_attempt and phenotype_production records remain consistent.
    phenotype_attempt = Public::PhenotypeAttempt.find(@mouse_allele_mod.phenotype_attempt.id)
    phenotyping_attempt_json = JSON.parse(phenotype_attempt.to_json)

    phenotyping_attempt_json['phenotyping_productions_attributes'] << params['phenotyping_production']
    phenotype_attempt.update_attributes(phenotyping_attempt_json)

    respond_with @phenotyping_production do |format|
      format.json do
        if phenotype_attempt.valid?
          @phenotyping_production = phenotype_attempt.phenotyping_productions.where("colony_name = '#{params['phenotyping_production']['colony_name']}'").first
          render :json => @phenotyping_production
        else
          render :json => phenotype_attempt.errors.messages
        end
      end
    end
  end


  def update
    @phenotyping_production =  Public::PhenotypingProduction.find(params['id'])

    return if @phenotyping_production.blank?
    # update through phenotype_attempt. This ensures pheotype_attempt and phenotype_production records remain consistent.
    phenotype_attempt = Public::PhenotypeAttempt.find(@phenotyping_production.phenotype_attempt.id)
    phenotyping_attempt_json = JSON.parse(phenotype_attempt.to_json)

    puts "HELLO"
    phenotyping_attempt_json['phenotyping_productions_attributes'].each do |pp|
      puts "#{pp}"
      if pp['id'] == @phenotyping_production.id
        pp.each do |key, value|
          if params[:phenotyping_production].keys.include?(key) && PhenotypingProduction.attribute_names.include?(key)
            pp[key] = params[:phenotyping_production][key]
          elsif key != 'id'
            pp.delete(key)
          end
        end
        puts "#{pp}"
      end
    end

    puts "We are here #{phenotyping_attempt_json}"
    phenotype_attempt.update_attributes(phenotyping_attempt_json)

    respond_with @phenotyping_production do |format|
      format.json do
        if phenotype_attempt.valid?
          @phenotyping_production.reload
          render :json => @phenotyping_production
        else
          render :json => phenotype_attempt.errors.messages
        end
      end
    end
  end



  def show
    @phenotyping_production = Public::PhenotypingProduction.find(params[:id])
    respond_with @phenotyping_production do |format|
      format.json do
        render :json => @phenotyping_production
      end
    end
  end

  def colony_name
    @phenotyping_production = Public::PhenotypingProduction.find_by_colony_name(params[:colony_name])
    respond_with @phenotyping_production do |format|
      format.json do
        render :json => @phenotyping_production
      end
    end
  end

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'id asc', Public::PhenotypingProduction, :public_search, false)
      end
    end
  end
end
