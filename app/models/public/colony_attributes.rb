module Public::ColonyAttributes

  JSON_OPTIONS = {
    :except => ['background_strain_id'],
#    :include => {},
    :methods => ['background_strain_name', 'distribution_centres_attributes', 'trace_files_attributes', 'alleles_attributes']
  }

  def colonies_attributes
    return colonies.as_json(JSON_OPTIONS)
  end
end
