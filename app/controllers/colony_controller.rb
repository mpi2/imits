class ColonyController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def show
    @id = params[:id]

    return if ! @id

    @colony = Colony.find_by_id @id

    @files = {}

    return if @colony.nil?


    marker_symbol = @colony.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
    if marker_symbol
      @title         = "Gene #{marker_symbol} - Colony #{@colony.name}"
    else
      @title         = "Colony #{@colony.name}"
    end

    if params[:filename]
      key = params[:filename].to_sym
      if @files.has_key? key
        send_data @files[key][:data], :filename => @files[key][:filename], :disposition => 'attachment'
      end

      return
    end

  end

  def phenotype_attempts_new
    @colony = Colony.find_by_name(params[:mi_attempt_colony_name])

    redirect_to :controller => 'phenotype_attempts', :action => :new, :colony_id => @colony.try(:id)
  end

  def mut_nucleotide_sequences
    @colony = Colony.find_by_id(params[:id])

    @mutsequences = @colony.get_mutant_nucleotide_sequence_features

    respond_with @mutsequences do |format|
      format.json do
        render :json => @mutsequences
      end
    end

  end
end
