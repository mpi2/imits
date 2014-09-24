class TargRep::Lims2SearchesController < TargRep::BaseController

  respond_to :json

  def get_crispr_group_data
    error = ""
    params_passed = true
    group_id = nil
    group_id = params[:group_id] if params.has_key?(:group_id)

    ## check Params
    if group_id.blank?
      error = "group_id required"
      params_passed = false
    end


    if params_passed
      response = lims2_call("api/crispr_group?id=#{group_id}")
      if response.message == 'Bad Request'
        error = "No crispr group data found for group_id: #{params[:marker_symbol]}"
      end
   end

    respond_to do |format|
      if error.blank?
        format.json { render :json => response.body.to_json}
      else
        format.json { render :json => error.to_json, status: 404}
      end
    end
  end



private
  def lims2_call(request_url_str)
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
