#!/usr/bin/env ruby

require 'pp'
require 'json'
require 'pathname'

OPTIONS = {
  :solr_url_dump => 'http://ikmc.vm.bytemark.co.uk:8984/solr',
  :dump_directory => "#{Rails.root}/tmp/solr_dump",
  :batch_size => 1000,
  :log => true,
  :cleanup => false,
  :solr_url_restore => 'http://htgt1.internal.sanger.ac.uk:8983/solr',
  :dump => false,
  :restore => true
}

module SolrConnect
  class Error < RuntimeError; end

  class NetHttpProxy
    def self.should_use_proxy_for?(host)
      ENV['NO_PROXY'].to_s.delete(' ').split(',').each do |no_proxy_host_part|
        if host.include?(no_proxy_host_part)
          return false
        end
      end

      return true
    end

    def initialize(solr_uri)
      if ENV['HTTP_PROXY'].present? and self.class.should_use_proxy_for?(solr_uri.host)
        proxy_uri = URI.parse(ENV['HTTP_PROXY'])
        @http = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
      else
        @http = Net::HTTP
      end
    end

    def start(*args, &block)
      @http.start(*args, &block)
    end
  end

  class Proxy
    def initialize(uri)
      @solr_uri = URI.parse(uri)
      @http = NetHttpProxy.new(@solr_uri)
    end

    def update(commands_packet, user = nil, password = nil)
      uri = @solr_uri.dup
      uri.path = uri.path + '/update/json'
      @http.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new uri.request_uri

        #TODO: enable the following when the /update route is secure
        #request.basic_auth(user, password) if user && password

        request.content_type = 'application/json'
        request.body = commands_packet
        http_response = http.request(request)
        handle_http_response_error(http_response, request)
      end
    end

    def search(solr_params)
      docs = nil
      uri = @solr_uri.dup
      uri.query = solr_params.merge(:wt => 'json').to_query
      uri.path = uri.path + '/select'

      @http.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        http_response = http.request(request)
        handle_http_response_error(http_response)

        response_body = JSON.parse(http_response.body)
        docs = response_body.fetch('response').fetch('docs')
      end
      return docs
    end

    def cores
      docs = nil
      uri = @solr_uri.dup
      uri.query = {:action => 'STATUS', :wt => 'json'}.to_query
      uri.path = uri.path + '/admin/cores'

      #puts "#### cores path"
      #pp uri.path

      the_cores = nil
      cc = {}

      @http.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        http_response = http.request(request)
        handle_http_response_error(http_response)

        response_body = JSON.parse(http_response.body)
        the_cores = response_body.fetch('status').keys

        the_cores.each do |c|
          cc[c] = {
            'name' => c,
            'numDocs' => response_body.fetch('status').fetch(c).fetch('index').fetch('numDocs'),
            'current' => response_body.fetch('status').fetch(c).fetch('index').fetch('current'),
            'lastModified' => response_body.fetch('status').fetch(c).fetch('index').fetch('lastModified')
          }
        end
      end
      return cc
    end

    def handle_http_response_error(http_response, request = nil)
      if ! http_response.kind_of? Net::HTTPSuccess
        raise SolrConnect::Error, "Error during update_json: #{http_response.message}\n#{http_response.body}\n\nRequest body:#{request.body}"
      end
    end

    protected :handle_http_response_error
  end
end

class SolrCommon
  include ActionView::Helpers::NumberHelper

  attr_accessor :options
  attr_accessor :solr

  def initialize(options = nil)
    @options = options
    @solr = {}
  end

  #def options
  #  @options
  #end

  def log message
    puts "#### " + message if @options[:log]
  end

  def _prologue
    raise "You must implement _prologue!"
  end

  def _epilogue
    raise "You must implement _epilogue!"
  end

  def _run
    raise "You must implement _run!"
  end

  def run
    _prologue
    _run
    _epilogue
  end
end

class SolrDump < SolrCommon
  def initialize(options = nil)
    super
    @options = options
  end

  def _prologue
    # make sure we can ping the solr
  end

  def _epilogue
    # do clean-up
  end

  #def ping(core)
  #  #    command = 'curl -s SOLR_SUBS/admin/ping |grep -o -E "name=\"status\">([0-9]+)<"|cut -f2 -d\>|cut -f1 -d\<'.gsub(/SOLR_SUBS/, SOLR_UPDATE[Rails.env]['index_proxy']['allele2'])
  #  SolrConnect::Proxy.new(@options[:solr_url_dump]).ping core
  #end

  def cores
    cores = SolrConnect::Proxy.new(@options[:solr_url_dump]).cores
    @solr['cores'] = cores
  end

  def zip input_filenames, zipfile_name
    Zip::Archive.open(zipfile_name, Zip::CREATE | Zip::TRUNC) do |ar|
      input_filenames.each do |filename|
        basename = Pathname.new(filename).basename
        ar.add_file(basename.to_s, filename)
      end
    end
  end

  def dump_core(core)
    # make save folder
    # grab all data
    # split in to batches

    #  pp core

    dump_directory = "#{@options[:dump_directory]}/#{core['name']}"

    # pp targets
    #  return

    dump_directory = "#{@options[:dump_directory]}/#{core['name']}"

    FileUtils.mkdir_p dump_directory

    # pp dump_directory

    do_dump = true

    if do_dump
      proxy = SolrConnect::Proxy.new(@options[:solr_url_dump] + "/" + core['name'])

      docs = proxy.search(:q => "*:*", :rows => core['numDocs'])

      # pp docs.size

      counter = 0
      docs.in_groups_of(@options[:batch_size], false) do |group|
        jcounter = "%05d" % counter.to_i
        File.open("#{dump_directory}/dump_#{jcounter}.json", 'w') {|f| f.write(JSON.pretty_generate(group)) }
        counter += 1
      end

      targets = Dir.glob(dump_directory + "/*.json")

      now = Time.now
      time_formatted = "#{now.year}-#{now.month.to_s.rjust(2, "0")}-#{now.day.to_s.rjust(2, "0")}-#{now.hour.to_s.rjust(2, "0")}-#{now.min.to_s.rjust(2, "0")}-#{now.sec.to_s.rjust(2, "0")}"
      #puts "#### time_formatted: #{time_formatted}"

      #zip_filename = "#{@options[:dump_directory]}/#{core['name']}_#{Time.now.to_formatted_s(:number)}.zip"
      zip_filename = "#{@options[:dump_directory]}/#{core['name']}_#{time_formatted}.zip"

      zip targets, zip_filename

      if File.exists?(zip_filename)
        size = number_to_human_size File.size(zip_filename)
        puts "#### #{zip_filename}: #{size}"
      end

    end

    if File.directory?(dump_directory)
      #puts "#### FileUtils.rm #{dump_directory}/*.json"
      #Dir.glob("#{dump_directory}/*.json").each { |f| puts "#### File.delete(#{f})" }
      puts "#### rm #{dump_directory}/*.json"
      puts "#### FileUtils.rmdir #{dump_directory}"
      #FileUtils.rm "#{dump_directory}/*.json" if @options[:cleanup]
      Dir.glob("#{dump_directory}/*.json").each { |f| File.delete(f) } if @options[:cleanup]
      FileUtils.rmdir dump_directory if @options[:cleanup]
    end

    #sorted = Dir.glob("#{@options[:dump_directory]}/#{core['name']}_*.zip").sort_by {|f| p f; File.mtime(File.join("#{@options[:dump_directory]}/",f))}
    #sorted = Dir.glob("#{@options[:dump_directory]}/#{core['name']}_*.zip").sort_by {|f| p File.mtime(f); File.mtime(f)}
    sorted = Dir.glob("#{@options[:dump_directory]}/#{core['name']}_*.zip").sort_by {|f| File.mtime(f)}.reverse
    # puts sorted.first, sorted.last

    #puts "### list:"
    #pp sorted

    if sorted.size > 5
      targets = sorted.last(sorted.size - 5)
      #puts "### delete:"
      #pp targets

      targets.each do |f|
        puts "#### FileUtils.rm #{f}"
        FileUtils.rm f if @options[:cleanup]
      end
    end

  end

  def _run
    # work out what the cores are: http://localhost:8983/solr/admin/cores?action=STATUS
    # http://stackoverflow.com/questions/6668534/how-can-i-get-a-list-of-all-the-cores-in-a-solr-server-using-solrj

    puts "#### solr: #{@options[:solr_url_dump]}"

    cores

    @solr['cores'].keys.each do |core|
      #next if core != 'gene2'
      log "Dumping " + core + " core"
      dump_core(@solr['cores'][core])
      #break
    end
  end
end

class SolrRestore < SolrCommon
  def initialize(options = nil)
    super
    @options = options
  end

  def _prologue
    # make sure we can ping the solr
  end

  def _epilogue
    # do clean-up
  end

  def cores
    cores = SolrConnect::Proxy.new(@options[:solr_url_restore]).cores
    @solr['cores'] = cores
  end

  def _run
    solr_url_restore = @options[:solr_url_restore]

    puts "#### solr: #{solr_url_restore}"

    #    exit

    # pp @options

    cores

    #pp cores

    @solr['cores'].keys.each do |core|
      dump_directory = "#{@options[:dump_directory]}/#{core}"
      #puts "#### dump_directory: #{dump_directory}"
      targets = Dir.glob(dump_directory + "/*.json")

      #next if core != 'gene2'

      # pp targets

      next if targets.size == 0

      log "Restoring " + core + " core"

      proxy = SolrConnect::Proxy.new(solr_url_restore + "/" + core)

      proxy.update({'delete' => {'query' => '*:*'}}.to_json, @solr_user, @solr_password)

      targets.each do |target|
        file = File.open(target, "rb")
        contents = file.read
        proxy.update(contents, @solr_user, @solr_password)
      end

      proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)

      # exit
    end
  end
end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd

  SolrDump.new(OPTIONS).run if OPTIONS[:dump]

  SolrRestore.new(OPTIONS).run if OPTIONS[:restore]
end
