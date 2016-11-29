# encoding: utf-8

class Rest::CentreSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    name
    mgi_strain_accession_id
    mgi_strain_name  
  }


  def initialize(strain, options = {})
    @options = options
    @strain = strain
  end

  def as_json
    json_hash = super(@strain, @options)
    return json_hash
  end
end
