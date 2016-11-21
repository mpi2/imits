# encoding: utf-8

class Rest::DistributionCentreSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    start_date
    end_date
    deposited_material_name
    centre_name
    is_distributed_by_emma
    distribution_network
  }

  def initialize(distribution_centre)
    @distribution_centre = distribution_centre
  end

  def as_json
    json_hash = super(@distribution_centre)
    return json_hash
  end
end

# COMPLETE
# FULL_ACCESS_ATTRIBUTES = %w{
#    name
#    contact_name
#    contact_email
#  }
#
#  READABLE_ATTRIBUTES = %w{
#    id
#    code
#    superscript
#  } 