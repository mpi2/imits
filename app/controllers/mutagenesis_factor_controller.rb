class MutagenesisFactorController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def crisprs

    @mutagenesis_factor = MutagenesisFactor.find_by_id(params[:id])

    @crisprs_list = []

    crisprs = @mutagenesis_factor.crisprs
    crisprs.each do |crispr|
        parent_feature = build_crispr_features(crispr)
        @crisprs_list.push( parent_feature )
    end

    respond_with @crisprs_list do |format|
      format.json do
        render :json => @crisprs_list
      end
    end
  end

  def vector
    @mutagenesis_factor = MutagenesisFactor.find_by_id(params[:id])
    mi_attempt = @mutagenesis_factor.mi_attempt

#    @vector = @mutagenesis_factor.donors

    @vector_features = []

#    if @vector
#      @allele      = @vector.allele
#      allele_type  = @allele.type
#
#      #   "TargRep::HdrAllele" -> oligo
#      case allele_type
#        when "TargRep::GeneTrap", "TargRep::CrisprTargetedAllele", "TargRep::TargetedAllele"
#            parent_feature = build_vector_features()
#        else
#          puts "Error: Allele type #{allele_type} not recognised as a vector."
#      end
#
#      @vector_features.push(parent_feature)
#    end
#
    respond_with @vector_features do |format|
      format.json do
        render :json => @vector_features
      end
    end
  end

  def designs

    position = params[:position]
    ids_str = params.has_key?(:ids) ? params[:ids].split(',') : []
    chr = nil
    coord_start = nil
    coord_end = nil
    unless position.blank?
      chr, coord = position.split(':')
      coord_start, coord_end = coord.split('-')
    end

    crisprs = []
    @crisprs_list = []

    if !chr.blank? && !coord_start.blank? && !coord_end.blank?
      if !ids_str.blank?
        crisprs = TargRep::Crispr.where("chr = '#{chr}' AND start > :coord_start AND start < :coord_end AND mutagenesis_factor_id IN ( :ids_str )", {coord_start: coord_start, coord_end: coord_end, ids_str: ids_str})
      else
        crisprs = TargRep::Crispr.where("chr = '#{chr}' AND start > :coord_start AND start < :coord_end", {coord_start: coord_start, coord_end: coord_end})
      end
    elsif !ids_str.blank?
      crisprs = TargRep::Crispr.where("mutagenesis_factor_id IN ( :ids_str )", {ids_str: ids_str})
    end

    crisprs.each do |crispr|
        parent_feature = build_crispr_features(crispr)
        @crisprs_list.push( parent_feature )
    end

    respond_with @crisprs_list do |format|
      format.json do
        render :json => @crisprs_list
      end
    end    
    
  end

  private
    def build_crispr_features(crispr)
      puts "Error: no crispr present " unless crispr
      return unless crispr

      # <TargRep::Crispr id: 124,
      # mutagenesis_factor_id: 68,
      # sequence: "CCGAGATTCTGCTACAGTCGCTC",
      # chr: "12",
      # start: 3958132,
      # end: 3958154,
      # created_at: "2014-06-04 11:24:12">

      sequence = crispr.sequence

      parent_feature = {
        'design_id'   => crispr.mutagenesis_factor.external_ref,
        'chr'         => crispr.chr,
        'name'        => 'CRISPR',
        'start'       => crispr.start,
        'end'         => crispr.end,
        'sequence'    => crispr.sequence,
        'cds'         => []
      }

      # we don't store where the PAM sites are currently so we have to look for CC/GG at ends
      # NB this may result in us finding a 'pam' site at both ends

      # NB seem to have to add 1 to ends to get to draw last nucleotide
      central_feature_details = {
        'design_id'  => crispr.mutagenesis_factor.external_ref,
        'chr'        => crispr.chr,
        'name'       => 'gRNA',
        'type'       => 'CDS',
        'start'      => crispr.start,
        'end'        => crispr.end.to_i + 1,
        'color'      => '#45A825'
      }

      if ['GG','CC'].include?(sequence[0..1])
        # PAM left features
        pam_left_details = {
          'design_id'   => crispr.mutagenesis_factor.external_ref,
          'chr'         => crispr.chr,
          'name'        => 'PAM',
          'type'        => 'CDS',
          'start'       => crispr.start,
          'end'         => crispr.start.to_i + 3,
          'color'       => '#1A8599'
        }
        parent_feature['cds'].push(pam_left_details)
        central_feature_details['start'] = ( crispr.start.to_i + 3 )
      end

      if ['GG','CC'].include?(sequence[-2..-1])
        # PAM left features
        pam_right_details = {
          'design_id'   => crispr.mutagenesis_factor.external_ref,
          'chr'         => crispr.chr,
          'name'        => 'PAM',
          'type'        => 'CDS',
          'start'       => crispr.end.to_i - 2,
          'end'         => crispr.end.to_i + 1,
          'color'       => '#1A8599'
        }
        parent_feature['cds'].push(pam_right_details)
        central_feature_details['end'] = ( crispr.end.to_i - 2 )
      end

      parent_feature['cds'].push(central_feature_details)

      return parent_feature
    end

    def build_vector_features

      puts "Error: no allele present" unless @allele
      return unless @allele

      parent_feature = {
        'chr'            => @allele.chromosome,
        'strand'         => @allele.strand,
        'vector_name'    => @vector.name,
        'backbone_name'  => @allele.backbone,
        'cassette_name'  => @allele.cassette,
        'cassette_type'  => @allele.cassette_type,
        'cassette_start' => @allele.cassette_start,
        'cassette_end'   => @allele.cassette_end,
        'cds'            => []
      }

      # cassette details
      if @allele.cassette_start then
        cassette_details = {
          'chr'    => @allele.chromosome,
          'name'   => @allele.cassette,
          'type'   => 'CDS'
        }
        if @allele.strand == '+' then
          cassette_details['start'] = @allele.cassette_start
          cassette_details['end']   = @allele.cassette_end
        else
          cassette_details['start'] = @allele.cassette_end
          cassette_details['end']   = @allele.cassette_start
        end
        parent_feature['cds'].push(cassette_details)
        parent_feature['start']     = cassette_details['start']
        parent_feature['end']       = cassette_details['end']
      end

      # loxp details
      if @allele.loxp_start && @allele.loxp_end then
        parent_feature['loxp_start'] = @allele.loxp_start
        parent_feature['loxp_end']   = @allele.loxp_end
        loxp_details = {
          'chr'    => @allele.chromosome,
          'name'   => 'loxP site',
          'type'   => 'CDS'
        }
        if @allele.strand == '+' then
          loxp_details['start']    = @allele.loxp_start
          loxp_details['end']      = @allele.loxp_end
          parent_feature['end']    = @allele.loxp_end
        else
          loxp_details['start']    = @allele.loxp_end
          loxp_details['end']      = @allele.loxp_start
          parent_feature['start']  = @allele.loxp_end
        end
        parent_feature['cds'].push(loxp_details);
      end

      return parent_feature
    end
end
