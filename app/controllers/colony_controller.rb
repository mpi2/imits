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

  end

  def phenotype_attempts_new
    @colony = Colony.find_by_name(params[:mi_attempt_colony_name])

    redirect_to :controller => 'phenotype_attempts', :action => :new, :colony_id => @colony.try(:id)
  end

  def mut_nucleotide_sequences
    position = params[:position]
    ids_str = params.has_key?(:ids) ? params[:ids].split(',') : []
    chr = nil
    coord_start = nil
    coord_end = nil
    unless position.blank?
      chr, coord = position.split(':')
      coord_start, coord_end = coord.split('-')
    end

    annotations = []

    if !chr.blank? && !coord_start.blank? && !coord_end.blank?
      if !ids_str.blank?
        annotations = Allele::Annotation.joins(:allele).where("chr = '#{chr}' AND start > :coord_start AND start < :coord_end AND alleles.colony_id IN ( :ids_str )", {coord_start: coord_start, coord_end: coord_end, ids_str: ids_str})
      else
        annotations = Allele::Annotation.joins(:allele).where("chr = '#{chr}' AND start > :coord_start AND start < :coord_end", {coord_start: coord_start, coord_end: coord_end})
      end
    elsif !ids_str.blank?
      annotations = Allele::Annotation.joins(:allele).where("alleles.colony_id IN ( :ids_str )", {ids_str: ids_str})
    end

    mut_seq_features = []

    annotations.each do |tc_mod|
      mut_seq_feature = {
        'chr'          => tc_mod.chr,
        'start'        => tc_mod.start,
        'end'          => tc_mod.end,
        'ref_sequence' => tc_mod.ref_seq,
        'alt_sequence' => tc_mod.alt_seq,
        'sequence'     => tc_mod.alt_seq,
        'mod_type'     => tc_mod.mod_type
      }
      mut_seq_features.push( mut_seq_feature.as_json )
    end

    respond_with @mutsequences do |format|
      format.json do
        render :json => mut_seq_features
      end
    end

  end
end
