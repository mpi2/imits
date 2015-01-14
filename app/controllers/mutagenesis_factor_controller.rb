class MutagenesisFactorController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def crisprs

    @mutagenesis_factor = MutagenesisFactor.find_by_id(params[:id])

    @crisprs_list = []

    crisprs = @mutagenesis_factor.crisprs
    crisprs.each do |crispr|
        crispr_as_json = crispr.as_json

        @crisprs_list.push( crispr_as_json )
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

    @vector = @mutagenesis_factor.vector

    @vector_features = []

    if @vector
      @allele      = @vector.allele
      allele_type  = @allele.type

      #   "TargRep::GeneTrap"             -> vector
      #   "TargRep::CrisprTargetedAllele" -> vector
      #   "TargRep::TargetedAllele"       -> vector
      #   "TargRep::HdrAllele"            -> oligo

      case allele_type
        # when "TargRep::HdrAllele"
        #     puts "This is an oligo"
        when "TargRep::GeneTrap", "TargRep::CrisprTargetedAllele", "TargRep::TargetedAllele"
            parent_feature = build_vector_features()
        else
          puts "Error: Allele type #{allele_type} not recognised as a vector."
      end

      @vector_features.push(parent_feature)
    # else
    #     puts "No vector found"
    end

    respond_with @vector_features do |format|
      format.json do
        render :json => @vector_features
      end
    end
  end

  def build_vector_features()

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

  # def oligo
  #   @mutagenesis_factor = MutagenesisFactor.find_by_id(params[:mutagenesis_factor_id])
  #   @oligo = @mutagenesis_factor.oligo
  #   respond_with @oligo do |format|
  #     format.json do
  #       render :json => @oligo
  #     end
  #   end
  # end
end
