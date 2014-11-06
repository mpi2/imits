# encoding: utf-8

module ApplicationModel::DistributionCentre

  DISTRIBUTION_NETWORKS = %w{
    CMMR
    EMMA
    MMRRC
  }

  FULL_ACCESS_ATTRIBUTES = %w{
    start_date
    end_date
    deposited_material_name
    centre_name
    is_distributed_by_emma
    distribution_network
    _destroy
  }

  READABLE_ATTRIBUTES = %w{
    id
  } + FULL_ACCESS_ATTRIBUTES

  ## This is for backwards compatibility with portal.
  def is_distributed_by_emma
    self.distribution_network == 'EMMA'
  end

  def is_distributed_by_emma=(bool)
    ## Set distribution_network to EMMA if `bool` is true
    if bool
      self.distribution_network = 'EMMA'
    ## Set distribution_network to nothing if `bool` is false and already set to EMMA, or leave as previous value.
    elsif is_distributed_by_emma
      self.distribution_network = nil
    end
  end

  ##
  # class method to calculate an order link
  ##
  def self.calculate_order_link( params, config = nil )

    distribution_centre_name  = params[:distribution_centre_name]
    distribution_network_name = params[:distribution_network_name]
    production_centre_name    = params[:production_centre_name]
    reconciled                = params[:reconciled]
    available                 = params[:available]

    # attempt to use network contact (preferred or default) to make order link
    if ( ['MMRRC'].include?( distribution_network_name ) )
      if ( ( reconciled == 'true' ) && ( available == true ) )
        return self.compile_order_link( distribution_network_name, params, config )
      else
        puts "Order link not generated as available = <#{available}> and reconciled = <#{reconciled}>"
        return []
      end

    elsif ( ['EMMA', 'CMMR'].include?( distribution_network_name ) )
      return self.compile_order_link( distribution_network_name, params, config )

    elsif ( ( distribution_network_name.nil? ) || ( distribution_network_name == '' ) )
      # attempt to use distribution centre contact to make order link
      if ( ['UCD', 'KOMP Repo'].include?( distribution_centre_name ) )

        # use KOMP to create order link
        if ( ( reconciled == 'true' ) && ( available == true ) )
          return self.compile_order_link( 'KOMP', params, config )
        else
          puts "Order link not generated as available = <#{available}> and reconciled = <#{reconciled}>"
          return []
        end
      else
        # at this point we have no network, and distribution centre is not KOMP Repo or UCD
        # check if we have config or centre contact details for the distribution centre
        if ( config.has_key?( distribution_centre_name ) && ( ( ( !config[distribution_centre_name][:default].blank? ) || ( !config[distribution_centre_name][:preferred].blank? ) ) || ( Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?( distribution_centre_name ) ) ) )
          return self.compile_order_link( distribution_centre_name, params, config )
        end

        # cannot use the distribution centre, attempt to use the production centre
        if ( !production_centre_name.nil? && ( Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?( production_centre_name ) ) )
          return self.compile_order_link( production_centre_name, params, config )
        else
          raise "No contact details available for production centre <#{production_centre_name}>, cannot generate order link"
        end
      end

    else
      # network not recognised
      raise "Distribution network name <#{distribution_network_name}> not recognised, cannot generate order link"
    end

  end

  ##
  # Compiles an order link given a config name (network, distribution or production centre name), parameters
  # and a configuration
  ##
  def self.compile_order_link( config_name, params, config = nil )

    raise "Expecting to find config key name to compile order link" if config_name.nil?

    config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

    # check the config contains the main repositories
    raise "Expecting to find KOMP in distribution centre config"  if ! config.has_key? 'KOMP'
    raise "Expecting to find EMMA in distribution centre config"  if ! config.has_key? 'EMMA'
    raise "Expecting to find MMRRC in distribution centre config" if ! config.has_key? 'MMRRC'
    raise "Expecting to find CMMR in distribution centre config"  if ! config.has_key? 'CMMR'

    order_from_name ||= []
    order_from_url  ||= []

    current_time = Time.now

    if params[:dc_start_date]
      start_date = params[:dc_start_date]
    else
      start_date = current_time
    end

    if params[:dc_end_date]
      end_date = params[:dc_end_date]
    else
      end_date = current_time
    end

    range = start_date.to_time..end_date.to_time

    if ( ! range.cover?(current_time) )
      raise "Distribution Centre date range not current, cannot create order link"
    end

    details = ''
    order_from_name = config_name

    if ( config.has_key?(config_name) && ( ( !config[config_name][:default].blank? ) || ( !config[config_name][:preferred].blank? ) ) )
      details = config[config_name]

      if ( !config[config_name][:default].blank? )
        order_from_url  = details[:default]
      end # default

      if ( !config[config_name][:preferred].blank? )
        project_id    = params[:ikmc_project_id]
        marker_symbol = params[:marker_symbol]

        if ( project_id && ( details[:preferred] =~ /PROJECT_ID/ ) )
          order_from_url = details[:preferred].gsub( /PROJECT_ID/, project_id )
        elsif ( marker_symbol && ( details[:preferred] =~ /MARKER_SYMBOL/ ) )
          order_from_url = details[:preferred].gsub( /MARKER_SYMBOL/, marker_symbol )
        end
      end # preferred

    else
      # no useful entry in config, attempt to use centre contact
      centre = Centre.where("contact_email IS NOT NULL AND name = '#{config_name}'").first
      if centre
        details = centre
        order_from_url = "mailto:#{details.contact_email}?subject=Mutant mouse enquiry"
      end
    end

    if ( order_from_name.blank? || order_from_url.blank? )
      raise "Order from name or url blank, failed to create order link"
    else
      return [ order_from_name, order_from_url ]
    end
  end

end