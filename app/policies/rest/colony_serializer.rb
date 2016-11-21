# encoding: utf-8

class Rest::ColonySerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    name
    genotype_confirmed
    background_strain_name
    allele_symbol
    mgi_allele_symbol_superscript
    mgi_allele_symbol_without_impc_abbreviation
    mgi_allele_id
    report_to_public
    private
  }


  def initialize(colony)
    @colony = colony
    @distribution_centres = colony.distribution_centres
  end

  def as_json
    json_hash = super(@colony)
    json_hash['distribution_centres_attributes'] = distribution_centres_attributes

    return json_hash
  end

  def distribution_centres_attributes
    distribution_centres_hash = []
    @distribution_centres.each do |distribution_centre|
      distribution_centres_hash << Rest::DistributionCentreSerializer.new(distribution_centre).as_json
    end

    return distribution_centres_hash
  end
end

#  COMPLETE
#  FULL_ACCESS_ATTRIBUTES = %w{
#    name
#    genotype_confirmed
#    report_to_public
#    allele_name
#    mgi_allele_symbol_superscript
#    background_strain_name  
#    mgi_allele_symbol_without_impc_abbreviation
#  }
#
#  READABLE_ATTRIBUTES = %w{
#    id
#    private
#    crispr_allele_category
#    mgi_allele_id
#
#  }
