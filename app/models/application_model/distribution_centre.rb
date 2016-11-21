# encoding: utf-8

module ApplicationModel::DistributionCentre

  DISTRIBUTION_NETWORKS = %w{
    CMMR
    EMMA
    MMRRC
  }

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

  def validate_distribution_centre_entry( dc )
    if dc.distribution_network.blank?
      if dc.centre.name == 'UCD'
        dc.errors.add(:base, 'When the distribution network is blank use distribution centre KOMP Repo rather than UCD.')
      end
    end

    if dc.distribution_network == 'MMRRC'
      if dc.centre.name != 'UCD'
        dc.errors.add(:base, 'When distribution network is set to MMRRC you must set the distribution centre to UCD.')
      end
    end

    if ['EMMA', 'CMMR'].include?( dc.distribution_network )
      if ( dc.centre.name == 'KOMP Repo' )
        dc.errors.add(:base, 'The distribution network cannot be set to anything other than MMRRC for distribution centres KOMP Repo or UCD. If you want to indicate that you are distributing to another network then you need to create another distribution centre for your production centre and then select the new network.')
      end
    end
  end

  # TODO: excluded for simplicity Nov 2014
  # def update_whether_distribution_centre_available
  #   puts "update_whether_distribution_centre_available: CHECKING IF AVAILABLE"
  #   puts "update_whether_distribution_centre_available: Current centre name = #{self.centre.name}"

  #   if ( ['KOMP Repo', 'UCD'].include?( self.centre.name ) )
  #     puts "update_whether_distribution_centre_available: Centre name is KOMP Repo or UCD"

  #     if self.changed? && self.changed_attributes.has_key?('centre_id')
  #       puts "update_whether_distribution_centre_available: Centre has changed to KOMP Repo or UCD, set available false"
  #       self.available = false
  #     end
  #   else
  #     if ( self.available == false )
  #       self.available = true
  #       puts "update_whether_distribution_centre_available: Updating available to true from false"
  #     end
  #   end
  # end

  ##
  # class method to calculate an order link
  ##
  def self.calculate_order_link( params, config = nil )

    distribution_centre_name  = params[:distribution_centre_name]
    distribution_network_name = params[:distribution_network_name]
    production_centre_name    = params[:production_centre_name]
    reconciled                = params[:reconciled]
    available                 = params[:available]

    config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

    # check the config contains the main repositories
    raise "Expecting to find KOMP in distribution centre config"  if ! config.has_key? 'KOMP'
    raise "Expecting to find EMMA in distribution centre config"  if ! config.has_key? 'EMMA'
    raise "Expecting to find MMRRC in distribution centre config" if ! config.has_key? 'MMRRC'
    raise "Expecting to find CMMR in distribution centre config"  if ! config.has_key? 'CMMR'

    # attempt to use network contact (preferred or default) to make order link
    if ( ['MMRRC'].include?( distribution_network_name ) )
      # TODO: redmine ticket 11984 reactivate check on available and reconciled flags once MMRRC repository data is reconciled
      # if reconciled == 'true' && available
      return self.compile_order_link( distribution_network_name, params, config )
      # else
      #   return self.calculate_order_link_for_production_centre( production_centre_name, params, config )
      # end

    elsif ( ['EMMA', 'CMMR'].include?( distribution_network_name ) )
      return self.compile_order_link( distribution_network_name, params, config )

    elsif ( ( distribution_network_name.nil? ) || ( distribution_network_name == '' ) )
      # attempt to use distribution centre contact to make order link
      if ( ['UCD', 'KOMP Repo'].include?( distribution_centre_name ) )
        if reconciled == 'true' && available
          # use KOMP to create order link
          return self.compile_order_link( 'KOMP', params, config )
        else
          # attempt to use production centre to create the link here
          return self.calculate_order_link_for_production_centre( production_centre_name, params, config )
        end
      else
        # at this point we have no network, and distribution centre is not KOMP Repo or UCD
        # check if we can use the distribution centre contact
        if (
            (
                config.has_key?( distribution_centre_name ) && (
                  ( !config[distribution_centre_name][:default].blank? ) ||
                  ( !config[distribution_centre_name][:preferred].blank? ))
            ) \
            || Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?( distribution_centre_name )
          )
          return self.compile_order_link( distribution_centre_name, params, config )
        end

        # cannot use the distribution centre, attempt to use the production centre
        return self.calculate_order_link_for_production_centre( production_centre_name, params, config )
      end

    else
      raise "Distribution network name <#{distribution_network_name}> not recognised, cannot generate order link"
    end

  end

  def self.calculate_order_link_for_production_centre( production_centre_name, params, config )

    if ( !production_centre_name.nil? && (
          Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?( production_centre_name )
        )
    )
      return self.compile_order_link( production_centre_name, params, config )
    else
      raise "No contact details available for production centre <#{production_centre_name}>, cannot generate order link"
    end

  end

  ##
  # Compiles an order link given a config name (network, distribution or production centre name), parameters
  # and a configuration
  ##
  def self.compile_order_link( config_name, params, config )

    raise "Expecting to find config key name to compile order link" if config_name.nil?

    raise "Distribution centre config cannot be nil"  if config.nil?

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