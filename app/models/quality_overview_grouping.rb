# encoding: utf-8

class QualityOverviewGrouping

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :consortium, :production_centre
  attr_accessor :quality_overviews

  def persisted?
    false
  end

end
