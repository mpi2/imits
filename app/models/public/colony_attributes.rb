module Public::ColonyAttributes

  JSON_OPTIONS = {
    :except => ['background_strain_id'],
#    :include => {},
    :methods => ['background_strain_name', 'distribution_centres_attributes', 'alleles_attributes', 'trace_call_attributes',  'allele_symbol']
  }

  def colonies_attributes
    return colonies.as_json(JSON_OPTIONS)
  end
end
