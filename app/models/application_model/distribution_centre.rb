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

  # class method to calculate an order link
  def self.calculate_order_link( params, config = nil )

    puts 'In class method'
    puts "Config passed in" if config

    config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

    raise "Expecting to find KOMP in distribution centre config"  if ! config.has_key? 'KOMP'
    raise "Expecting to find EMMA in distribution centre config"  if ! config.has_key? 'EMMA'
    raise "Expecting to find MMRRC in distribution centre config" if ! config.has_key? 'MMRRC'
    raise "Expecting to find CMMR in distribution centre config"  if ! config.has_key? 'CMMR'

    order_from_name ||= []
    order_from_url  ||= []

    puts "----input params:-----"
    pp params
    puts "-----end params------"

    config_name = params[:distribution_centre_name]

    if ( ['EMMA', 'KOMP', 'MMRRC', 'CMMR'].include?(params[:distribution_network_name]) )
      puts "distribution_network_name recognised"
    else
      puts "distribution_network_name NOT recognised"
      if ( ['UCD', 'KOMP Repo'].include?(config_name) )
        puts "distribution_centre_name is set to KOMP Repo or UCD"
      else
        puts "distribution_centre_name is NOT set to KOMP Repo or UCD"
        if ( config.has_key?(config_name) && (!config[config_name][:default].blank? || !config[config_name][:preferred].blank?) )
          puts "distribution_centre_name is in config so likely has contact details"
        else
          puts "distribution_centre_name is NOT in config"
          if ( Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?(config_name))
            puts "distribution_centre_name has a contact email address"
          else
            puts "distribution_centre_name does not have an contact email address"
            raise "Unrecognised or missing distribution network and unrecognised centre with no contact email address"
          end
        end
      end
    end

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

    puts "Checking time range"
    if ! range.cover?(current_time)
      puts "Not covered at current time"
      raise "Distribution Centre date range not current, cannot create order links"
    end

    centre = Centre.where("contact_email IS NOT NULL AND name = '#{params[:distribution_centre_name]}'").first
    # override config_name if necessary (rules enforced by model validation)
    config_name = 'KOMP' if ['UCD', 'KOMP Repo'].include?(params[:distribution_centre_name])
    config_name = params[:distribution_network_name] if !params[:distribution_network_name].blank?

    details = ''

    if config_name
      puts "config_name = #{config_name}"
    else
      puts "config_name is blank"
    end
    puts "centre is blank" if centre.nil?

    if ( config.has_key?(config_name) && (!config[config_name][:default].blank? || !config[config_name][:preferred].blank?) )
      puts "config_name has either default or preferred order link in config"

      details         = config[config_name]
      order_from_url  = details[:default]
      order_from_name = config_name

      if !config[config_name][:preferred].blank?

        puts "Centre preferred yaml is not blank"
        project_id    = params[:ikmc_project_id]
        marker_symbol = params[:marker_symbol]

        puts "project_id    = #{project_id}"    unless project_id.nil?
        puts "marker_symbol = #{marker_symbol}" unless marker_symbol.nil?

        # order of regex expression doesn't matter: http://stackoverflow.com/questions/5781362/ruby-operator

        if project_id && details[:preferred] =~ /PROJECT_ID/
          puts "url contains project id"
          order_from_url = details[:preferred].gsub(/PROJECT_ID/, project_id)
        end

        if marker_symbol && details[:preferred] =~ /MARKER_SYMBOL/
          puts "url contains marker symbol"
          order_from_url = details[:preferred].gsub(/MARKER_SYMBOL/, marker_symbol)
        end
      end
    elsif centre
      puts "Using Centre"
      details = centre
      order_from_url = "mailto:#{details.contact_email}?subject=Mutant mouse enquiry"
      order_from_name = config_name
    end

    if details.blank?
      puts "details blank"
      raise "Failed to select a centre with name <#{params[:distribution_centre_name]}> and a contact email address"
    end

    if order_from_url
      puts "order_from_name = #{order_from_name}"
      puts "order_from_url = #{order_from_url}"
      return [order_from_name, order_from_url]
    else
      raise "Order from url blank, failed to create order links"
    end

  end

end