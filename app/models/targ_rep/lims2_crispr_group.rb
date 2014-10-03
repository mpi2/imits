class TargRep::Lims2CrisprGroup

attr_accessor :mgi_accession_id, :group_id, :crispr_ids, :crispr_primers, :crisprs, :errors

#INSTANCE METHODS
  def initialize(params = {})
    if params.has_key?('error') and ! params['error'].blank?
      self.errors = params['error']
    else
      self.errors = params['errors'] || []
      self.mgi_accession_id = params['gene_id'] || nil
      self.group_id = params['id'] || nil
      self.crispr_ids = params['crispr_ids'] || []
      self.crispr_primers = params['crispr_primers'] || []
      self.crisprs = params['group_crisprs'] || []
    end
  end


  def crispr_list
    self.crisprs.map{|crispr| {:sequence => crispr['seq'],
                               :chr      => crispr['locus']['chr'],
                               :start    => crispr['locus']['chr_start'],
                               :end      => crispr['locus']['chr_end']
                               }}
  end


  def genotype_primer_list
    self.crispr_primers.map{|primer| {:name                     => primer['primer_name'],
                                      :sequence                 => primer['primer_seq'],
                                      :chr                      => primer['locus']['chr'],
                                      :genomic_start_coordinate => primer['locus']['chr_start'],
                                      :genomic_end_coordinate   => primer['locus']['chr_end']
                                      }}
  end



# CLASS METHODS
  def self.find_by_group_id(group_id = nil)
    if group_id.blank? or (! group_id.is_a? Integer)
      raise "Invalid group_id"
    end
    params = self.get_crispr_group("id=#{group_id}")

    crispr_group = TargRep::Lims2CrisprGroup.new(params)
    return crispr_group
  end




#PRIVATE METHODS
private

  def self.get_crispr_group(query)
    params = {}
    response = lims2_call("api/crispr_group?#{query}")
    if response.message == 'Bad Request'
      params['errors'] = 'crispr group not found'
      return params
    else
      params = JSON.parse(response.body)
    end
    return params
  end

# This should be separated out into a separate Lims2Base class, which this class and any other class requiring connection to Lims2 rest API can inherite
  def self.lims2_call(request_url_str)
    conf = YAML.load_file('config/services.yml')
    username = conf['lims2']['username']
    password = conf['lims2']['password']
    uri = URI("#{Rails.configuration.lims2_root}/#{request_url_str}&username=#{username}&password=#{password}")
    proxy_uri = ENV['HTTP_PROXY'] ? URI.parse(ENV['HTTP_PROXY']) : uri.hostname

    res = Net::HTTP.start(proxy_uri.host, proxy_uri.port) do |http|
      req = Net::HTTP::Get.new(uri.to_s)
      req.content_type = 'application/json'
      http.request(req)
    end
    res
  end
end