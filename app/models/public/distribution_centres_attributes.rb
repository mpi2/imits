module Public::DistributionCentresAttributes
  def distribution_centres_attributes
    return distribution_centres.map(&:as_json)
  end
end
