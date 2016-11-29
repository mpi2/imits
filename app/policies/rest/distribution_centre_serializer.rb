# encoding: utf-8

class Rest::DistributionCentreSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    start_date
    end_date
    deposited_material_name
    centre_name
    is_distributed_by_emma
    distribution_network
  }

  def initialize(distribution_centre, options = {})
    @options = options
    @distribution_centre = distribution_centre
  end

  def as_json
    json_hash = super(@distribution_centre, @options)
    return json_hash
  end
end
