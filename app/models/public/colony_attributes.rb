module Public::ColonyAttributes

#  JSON_OPTIONS = {
#    :except => [],
#    :include => {},
#    :methods => []
#  }

  def colonies_attributes
#    return colonies.as_json(JSON_OPTIONS)
     return colonies.as_json()
  end
end
