module Public::MutagenesisFactorAttributes

  JSON_OPTIONS = {
    :except => [:vector_id],
    :include => {:crisprs => { :except => [:created_at]}},
    :include => {:genotype_primers => { :except => [:created_at]}},
    :methods => [:vector_name]
  }

  def mutagenesis_factor_attributes
    return mutagenesis_factor.as_json(JSON_OPTIONS)
  end
end
