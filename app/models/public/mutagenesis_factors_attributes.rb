module Public::MutagenesisFactorsAttributes

  JSON_OPTIONS = {
    :except => [:vector_id],
    :include => {:crisprs => { :except => [:created_at]}},
    :include => {:genotype_primers => { :except => [:created_at]}},
    :methods => [:vector_name]
  }

  def mutagenesis_factors_attributes
    return mutagenesis_factors.as_json(JSON_OPTIONS)
  end
end
