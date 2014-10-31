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
  def self.calculate_order_link( params )

    puts 'In class method'

    config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

    raise "Expecting to find KOMP in distribution centre config"  if ! config.has_key? 'KOMP'
    raise "Expecting to find EMMA in distribution centre config"  if ! config.has_key? 'EMMA'
    raise "Expecting to find MMRRC in distribution centre config" if ! config.has_key? 'MMRRC'
    raise "Expecting to find CMMR in distribution centre config"  if ! config.has_key? 'CMMR'

    order_from_name ||= []
    order_from_url  ||= []

    puts "-------params:-------"
    pp params

    # TODO are these checks correct
    if ( ( ! ['EMMA', 'KOMP', 'MMRRC', 'CMMR'].include?(params[:distribution_network]) ) &&
      (! ['UCD', 'KOMP Repo'].include?(params[:centre_name]) ) &&
      (! (config.has_key?(params[:centre_name]) ) ||
      Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?(params[:centre_name]))
      )
      # TODO should this really return nothing?
      return []
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

    if ! range.cover?(current_time)
      puts "Not covered at this time"
      # TODO should this return nothing?
      return []
    end

    centre = Centre.where("contact_email IS NOT NULL AND name = '#{params[:centre_name]}'").first
    # rules enforced by model validation
    centre_name = 'KOMP' if ['UCD', 'KOMP Repo'].include?(params[:centre_name])
    centre_name = params[:distribution_network] if !params[:distribution_network].blank?

    details = ''

    if ( config.has_key?(centre_name) &&
      (!config[centre_name][:default].blank? ||
       !config[centre_name][:preferred].blank?) )
      # if blank then will default to order_from_url = details[:default]
      details         = config[centre_name]
      order_from_url  = details[:default]
      order_from_name = centre_name

      if !config[centre_name][:preferred].blank?

        puts "Centre preferred yaml is not blank"
        project_id    = params[:ikmc_project_id]
        marker_symbol = params[:marker_symbol]

        puts "project_id    = #{project_id}"    unless project_id.nil?
        puts "marker_symbol = #{marker_symbol}" unless marker_symbol.nil?

        # order of regex expression doesn't matter: http://stackoverflow.com/questions/5781362/ruby-operator

        if project_id &&  details[:preferred] =~ /PROJECT_ID/
          order_from_url = details[:preferred].gsub(/PROJECT_ID/, project_id)
        end

        if marker_symbol && details[:preferred] =~ /MARKER_SYMBOL/
          order_from_url = details[:preferred].gsub(/MARKER_SYMBOL/, marker_symbol)
        end
      end
    elsif centre
      details = centre
      order_from_url = "mailto:#{details.contact_email}?subject=Mutant mouse enquiry"
      order_from_name = centre_name
    end

    if details.blank?
      puts "details blank"
      return []
    end

    if order_from_url
      puts "order_from_name = #{order_from_name}"
      puts "order_from_url = #{order_from_url}"
      return [order_from_name, order_from_url]
    else
      return []
    end

  end

end