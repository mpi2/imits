class TargRep::AllelesController < TargRep::BaseController

  require 'allele_image'

  respond_to :html, :except => [:loa]
  respond_to :json

  before_filter do
    @klass = TargRep::Allele
    @title = 'Allele'
    @allele_type = @klass.name.demodulize.underscore
    @new_path = new_targ_rep_targeted_allele_path
  end

  # For webservice interface
  before_filter :format_nested_params, :only => [:create, :update]

  before_filter :authorize_admin_user!, :only => :destroy

  skip_before_filter :authenticate_user!, :only => [
    :show,
    :index,
    :targeting_vector_genbank_file,
    :escell_clone_genbank_file,
    :escell_clone_cre_genbank_file,
    :escell_clone_flp_genbank_file,
    :escell_clone_flp_cre_genbank_file,
    :allele_image,
    :allele_image_cre,
    :allele_image_flp,
    :allele_image_flp_cre,
    :cassette_image,
    :vector_image,
    :show_issue,
    :loa_primers
  ]

  # GET /alleles
  # GET /alleles.json
  def index
    params[:page] ||= 1
    params[:per_page] ||= 100
    allele_params = setup_allele_search(params)
    @alleles = @klass.order('targ_rep_alleles.created_at desc')
      .search(allele_params)
      .result(:distinct => true)
      .paginate(
        :page    => params[:page],
        :per_page => params[:per_page]
      )

    mutational_drop_downs
    options = {
        :methods => [
            :mutation_method_name,
            :mutation_type_name,
            :mutation_subtype_name,
            :marker_symbol
        ]}
    respond_to do |format|
      format.html {respond_with @alleles}
      format.json {respond_with @alleles.to_json(options)}
    end
  end

  # GET /alleles/1
  # GET /alleles/1.json
  def show
    @allele = @klass.find params[:id],
      :include => [
        { :targeting_vectors => :pipeline },
        { :es_cells => [ :pipeline ] }
      ]

    @es_cells = @allele.es_cells.sort{ |a,b| a.name <=> b.name }

    respond_with @allele

  end

  def show_issue
    core = params[:core].blank? ? "product" : params[:core]

    if core == "product"
      show_issue_product_core
    else
      Rails.logger.info "#### Unexpected core <#{params[:core]}> for Solr for allele with an issue"
    end

  end

  def show_issue_product_core
    @allele       = @klass.find(params[:allele_id])
    product_id    = params[:product_id]

    solr_update = YAML.load_file("#{Rails.root}/config/solr_update.yml")

    proxy = SolrBulkUpdate::Proxy.new(solr_update[Rails.env]['index_proxy']['product'])
    json_qry = { :q => 'product_id:' + product_id }
    docs = proxy.search(json_qry)

    if ( docs.nil? || docs.empty? )
      Rails.logger.info "#### Unable to fetch information for product_id #{product_id} from Solr for allele with an issue"
    elsif ( docs.length > 1 )
      Rails.logger.info "#### Multiple docs (#{docs.length}) returned for product_id #{product_id} from Solr for allele with an issue"
    else
      @order_from_names = docs[0].has_key?('order_names') ? docs[0]["order_names"] : nil
      @order_from_urls = docs[0].has_key?('order_links') ? docs[0]["order_links"] : nil
    end
  end

  ##
  ## Custom controllers
  ##

  def loa_primers
    allele_id = params[:id]
    return if allele_id.blank?

    @allele = @klass.find(allele_id)

    loa_pcrs = {}

    if ! @allele.blank?
      loa_pcrs['upstream'] = @allele.taqman_upstream_del_assay_id unless @allele.taqman_upstream_del_assay_id.blank?
      loa_pcrs['critical'] = @allele.taqman_critical_del_assay_id unless @allele.taqman_critical_del_assay_id.blank?
      loa_pcrs['downstream'] = @allele.taqman_downstream_del_assay_id unless @allele.taqman_downstream_del_assay_id.blank?
    end

    respond_to do |format|
      format.json { render :json => loa_pcrs.to_json }
    end
  end

  def history
    @allele = @klass.find(params[:id])
  end

  # GET /alleles/1/escell_clone_genbank_file/
  def escell_clone_genbank_file
    find_allele
    return if check_for_escell_genbank_file
    send_genbank_file(@allele.allele_genbank_file.file_gb)
  end

  # GET /alleles/1/targeting-vector-genbank-file/
  def targeting_vector_genbank_file
    find_allele
    return if check_for_vector_genbank_file
    send_genbank_file(@allele.vector_genbank_file.file_gb)
  end

  def escell_clone_cre_genbank_file
    find_allele
    return if check_for_escell_genbank_file
    send_genbank_file(@allele.allele_genbank_file.apply_cre.file_gb)
  end

  def escell_clone_flp_genbank_file
    find_allele
    return if check_for_escell_genbank_file
    send_genbank_file(@allele.llele_genbank_file.apply_flp.file_gb)
  end

  def escell_clone_flp_cre_genbank_file
    find_allele
    return if check_for_escell_genbank_file
    send_genbank_file(@allele.llele_genbank_file.apply_flp_cre.file_gb)
  end

  def send_genbank_file(genbank_string)
    send_data(
      "<pre>#{genbank_string}</pre>",
      {
        :type        => 'text/html',
        :disposition => 'inline'
      }
    )
  end

  def missing_required_data?
    return true if @allele.blank?

    if params[:type].blank?
      Rails.logger.info 'Incorrect usage. Please follow the links on the page to navigate between allele.'
      return true
    end

    if params[:type] == 'allele' && (@allele.allele_genbank_file.nil?)
      Rails.logger.info 'Could not find EsCell\'s Genbank file data.'
      return true
    elsif params[:type] == 'vector' && @allele.vector_genbank_file.blank?
      Rails.logger.info 'Could not find Targeting vector\'s Genbank file data.'
      return true
    end

    false
  end

  def genbank_data
    return nil if @allele.blank?

    if params[:method].blank? && (params[:type] == 'allele' || params[:type] == 'cassette')
      return @allele.allele_genbank_file.file_gb
    elsif params[:type] == 'allele' && params[:method] == 'cre'
      return @allele.allele_genbank_file.apply_cre.file_gb
    elsif params[:type] == 'allele' && params[:method] == 'flp'
      return @allele.allele_genbank_file.apply_flp.file_gb
    elsif params[:type] == 'allele' && params[:method] == 'flp_cre'
      return @allele.allele_genbank_file.apply_flp_cre.file_gb
    elsif params[:method].blank? && params[:type] == 'vector'
      return @allele.vector_genbank_file.file_gb
    end

    nil
  end

  def render_image(options = {})
    missing_data_image and return if missing_required_data? || genbank_data.blank?

    if params[:type] == 'cassette'
      options[:cassetteonly] = true
    end

    options[:mutation_type] = @allele.mutation_type_name

    if params[:old]
      send_allele_image(
        AlleleImage::Image.new(genbank_data, options).render.to_blob { self.format = "PNG" }
      )
    else
      send_allele_image(
        AlleleImage2::Image.new(genbank_data, options).render.to_blob { self.format = "PNG" }
      )
    end
  end

  def missing_data_image
    send_file(
      File.join(Rails.root, 'public', 'images', 'missing-allele-image.png'),
      :disposition => "inline", :type => "image/png"
    )
  end

  ## GET /alleles/1/image
  def image
    @allele = @klass.find_by_id(params[:id])
    render_image(params)
  end

  # GET /alleles/1/allele-image/
  def allele_image
    @allele = @klass.find_by_id(params[:id])
    params[:type] = 'allele'
    render_image(params)
  end

  # GET /alleles/1/allele-image-cre/
  def allele_image_cre
    @allele = @klass.find_by_id(params[:id])
    params[:type] = 'allele'
    params[:method] = 'cre'
    render_image(params)
  end

  # GET /alleles/1/allele-image-flp/
  def allele_image_flp
    @allele = @klass.find_by_id(params[:id])
    params[:type] = 'allele'
    params[:method] = 'flp'
    render_image(params)
  end

  # GET /alleles/1/allele-image-flp-cre/
  def allele_image_flp_cre
    @allele = @klass.find_by_id(params[:id])
    params[:type] = 'allele'
    params[:method] = 'flp_cre'
    render_image(params)
  end

  # GET /alleles/1/cassette-image/
  def cassette_image
    @allele = @klass.find_by_id(params[:id])
    params[:type] = 'cassette'
    render_image(params)
  end

  # GET /alleles/1/vector-image/
  def vector_image
    @allele = @klass.find_by_id(params[:id])
    params[:type] = 'vector'
    render_image(params)
  end


  def send_allele_image(allele_image)

    filename = String.new.tap do |s|

      s << "#{@allele.cassette}-"

      s << "#{@allele.mutation_type_name.parameterize.underscore}-"

      if params[:method]
        s << "#{params[:method]}-"
      end

      s << "#{@allele.id}-"
      s << "#{params[:type]}"

      if params[:simple]
        s << '-simple'
      end

      if params[:cassette]
        s << '-cassette'
      end

      s << ".png"
    end

    send_data(
      allele_image, :disposition => "inline", :type => "image/png", :filename => filename
    )
  end

  def attributes
    render :json => create_attribute_documentation_for(@klass)
  end

  def targeted_allele?; false; end
  def gene_trap?; false; end
  def hdr_allele?; false; end
  def nhej_allele?; false; end

  private
    def find_allele
      @allele = @klass.find(params[:id])
    end

    def mutational_drop_downs
      @mutation_type = TargRep::MutationType.all
      @mutation_subtype = TargRep::MutationSubtype.all
      @mutation_method = TargRep::MutationMethod.all
    end

    def setup_allele_search(params)
      allele_params = params.dup

      # Just keep Molecular Structure params.
      allele_params.delete "controller"
      allele_params.delete "action"
      allele_params.delete "format"
      allele_params.delete "page"
      allele_params.delete "per_page"
      allele_params.delete "utf8"

      if allele_params.include? :search
        allele_params = params[:search]
      elsif allele_params[:loxp_start] == 'null' and allele_params[:loxp_end] == 'null'
        # 'loxp_start_null' and 'loxp_end_null' should be used to force
        # these fields to be null
        allele_params.delete :loxp_start
        allele_params.delete :loxp_end
        allele_params.update :loxp_start_null => true, :loxp_end_null => true
      end

      allele_params.delete_if { |k, v| v.empty? }

      Rails.logger.debug allele_params.inspect

      return allele_params
    end

    def format_nested_params
      # Specific to create/update methods - webservice interface
      params[:targ_rep_allele] = params.delete(:molecular_structure) if params[:molecular_structure]
      params[:targ_rep_allele] = params.delete(:allele) if params[:allele]
      params[:targ_rep_allele] = params.delete(:targ_rep_gene_trap) if params[:targ_rep_gene_trap]
      params[:targ_rep_allele] = params.delete(:targ_rep_targeted_allele) if params[:targ_rep_targeted_allele]
      params[:targ_rep_allele] = params.delete(:targ_rep_crispr_targeted_allele) if params[:targ_rep_crispr_targeted_allele]
      params[:targ_rep_allele] = params.delete(:targ_rep_hdr_allele) if params[:targ_rep_hdr_allele]
      allele_params = params[:targ_rep_allele]

      # README: http://htgt.internal.sanger.ac.uk:4005/issues/257
      #
      # 'accepts_nested_attributes_for' (in model.rb) expects
      # <child_model>_attributes as a key in params hash in order to
      # create <child_model> objects.
      # For now, it is allowed to send a nested Array such as 'es_cells'
      # instead of the expected 'es_cell_attributes' Array.
      # This function will rename/move 'es_cells' to 'es_cell_attributes'.
      #
      # Because of the rails issue (see ticket):
      # This function will also add the 'nested => true' key/value pair to each
      # hash contained in the Array so that the model does not try to validate
      # the ES Cell before the molecular structure gets its ID (creation only).

      ##
      ##  ES Cells
      ##

      if allele_params.include? :es_cells
        allele_params[:es_cells].each do |attrs|
          attrs[:nested] = true
        end
        allele_params[:es_cells_attributes] = allele_params.delete(:es_cells)
      elsif not allele_params.include? :es_cells_attributes
        allele_params[:es_cells_attributes] = []
      end

      ##
      ##  Targeting Vectors + their ES Cells
      ##

      if allele_params.include? :targeting_vectors
        allele_params[:targeting_vectors].each do |attrs|
          attrs.update :nested => true

          # Move 'es_cells' Array related to this Targeting Vector
          # into the 'es_cells_attributes' Array created above.
          # es_cell hash will contain targeting_vector_name so that it can be
          # related to the proper targeting_vector when it gets an ID.
          if attrs.include? :es_cells
            attrs[:es_cells].each do |es_cell_attr|
              es_cell_attr.update :nested => true, :targeting_vector_name => attrs[:name]
              allele_params[:es_cells_attributes].push es_cell_attr
            end
            attrs.delete :es_cells
          end
        end

        allele_params[:targeting_vectors_attributes] = allele_params.delete(:targeting_vectors)
      end

      es_cell_attributes = allele_params[:es_cells_attributes].blank? ? [] : allele_params[:es_cells_attributes]
      es_cell_attributes.each do |key, attrs|
        if current_user != 'htgt@sanger.ac.uk'
          if !attrs.has_key?("id")
            attrs["production_centre_auto_update"] = false
          else
            es_cell = TargRep::EsCell.find(attrs["id"])
            if attrs.has_key?("report_to_public") && es_cell.report_to_public != (attrs["report_to_public"] == '1')
              attrs["production_centre_auto_update"] = false
            end
          end
        end
      end

      targeting_vector_attributes = allele_params[:targeting_vectors_attributes].blank? ? [] : allele_params[:targeting_vectors_attributes]
      targeting_vector_attributes.each do |key, attrs|
        if current_user != 'htgt@sanger.ac.uk'
          if !attrs.has_key?("id")
            attrs["production_centre_auto_update"] = false
          else
            targeting_vector = TargRep::TargetingVector.find(attrs["id"])
            if attrs.has_key?("report_to_public") && targeting_vector.report_to_public != (attrs["report_to_public"] == '1')
              attrs["production_centre_auto_update"] = false
            end
          end
        end
      end
      ##
      ##  Allele Sequence Anotation
      ##

      if allele_params.include?(:allele_sequence_annotations) && !allele_params.include?(:allele_sequence_annotations_attributes)
        allele_params[:allele_sequence_annotations].each { |attrs| attrs[:nested] = true }
        allele_params[:allele_sequence_annotations_attributes] = allele_params.delete(:allele_sequence_annotations)
      elsif not allele_params.include? :allele_sequence_annotations_attributes
        allele_params[:allele_sequence_annotations_attributes] = []
      end
    end

    def four_oh_four
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => "404 Not Found" }
        format.all { render :nothing => true, :status => "404 Not Found" }
      end
    end

    def check_for_escell_genbank_file
      four_oh_four if @allele.allele_genbank_file.blank?
    end

    def check_for_vector_genbank_file
      four_oh_four if @allele.vector_genbank_file.blank?
    end

    # One can give a targeting_vector_name instead of a targeting_vector_id
    # to link an ES Cell to its Targeting Vector.
    # This function will find the right targeting vector from the given name
    def update_links_escell_to_targ_vec allele_id, params
      return if params[:es_cells_attributes].blank?
      es_cells_attrs = []
      if params[:es_cells_attributes].is_a? Array
        params[:es_cells_attributes].each do |attrs|
          next if attrs[:name].blank?
          es_cells_attrs.push attrs
        end
      else
        params[:es_cells_attributes].each do |key, attrs|
          next if attrs[:name].blank?
          es_cells_attrs.push attrs
        end
      end

      es_cells_attrs.each do |attrs|
        next if attrs.include? :_destroy and attrs[:_destroy] == "1"

        if attrs.include? :targeting_vector_name

          # Find ES Cell from its 'id' or its 'name' + 'allele_id'
          if attrs.include? :id
            es_cell = TargRep::EsCell.find_by_id attrs[:id]
          else
            search  = TargRep::EsCell.search(:name_like => attrs[:name], :allele_id_is => allele_id).result
            es_cell = search.first
          end

          # Find targeting vector from given name and link it to the ES Cell
          if es_cell && es_cell.targeting_vector.nil? && !attrs[:targeting_vector_name].blank?
            es_cell.targeting_vector = TargRep::TargetingVector.find_by_name!(attrs[:targeting_vector_name])
            es_cell.save
          end
        end
      end
    end
end
