class TargRep::AllelesController < TargRep::BaseController
  
  respond_to :html, :xml, :json

  # For webservice interface
  before_filter :format_nested_params, :only => [:create, :update]

  before_filter :authorize_admin_user!, :only => :destroy

  # GET /alleles
  # GET /alleles.xml
  # GET /alleles.json
  def index
    params[:page] ||= 1
    params[:per_page] ||= 100
    allele_params = setup_allele_search(params)
    @alleles = TargRep::Allele.search(allele_params).result.paginate(
      :page    => params[:page],
      :per_page => params[:per_page],
      :select  => "distinct targ_rep_alleles.*",
      :include => [ { :targeting_vectors => :pipeline }, { :es_cells => :pipeline } ]
    )
    mutational_drop_downs

    respond_with @alleles
  end

  # GET /alleles/1
  # GET /alleles/1.xml
  # GET /alleles/1.json
  def show
    @allele = TargRep::Allele.find params[:id],
      :include => [
        :genbank_file,
        { :targeting_vectors => :pipeline },
        { :es_cells => [ :pipeline ] }
      ]

    @es_cells = @allele.es_cells.sort{ |a,b| a.name <=> b.name }

    respond_with @allele

  end

  # GET /alleles/new
  def new
    @allele = TargRep::Allele.new
    mutational_drop_downs
    @allele.genbank_file = TargRep::GenbankFile.new
    @allele.targeting_vectors.build
    @allele.es_cells.build
  end

  # GET /alleles/1/edit
  def edit
    @allele = TargRep::Allele.find params[:id],
      :include => [
        :genbank_file,
        { :targeting_vectors => :pipeline },
        { :es_cells => [ :pipeline ] }
      ]

    mutational_drop_downs
    @allele.genbank_file = TargRep::GenbankFile.new if @allele.genbank_file.nil?

    @allele.es_cells.each do |es_cell|
      es_cell.build_distribution_qc(current_user.es_cell_distribution_centre)
    end

    @allele.es_cells.sort!{ |a,b| a.name <=> b.name }
  end

  # POST /alleles
  # POST /alleles.xml
  # POST /alleles.json
  def create
    @allele = TargRep::Allele.new(params[:targ_rep_allele])
    mutational_drop_downs

    respond_to do |format|
      if @allele.save
        # Useful for all formats, not only HTML
        update_links_escell_to_targ_vec @allele.id, params[:targ_rep_allele]

        format.html {
          flash[:notice] = 'Allele successfully created.'
          redirect_to @allele
        }
        format.xml  { render :xml  => @allele, :status => :created, :location => @allele }
        format.json { render :json => @allele, :status => :created, :location => @allele }
      else
        format.html {
          @allele.genbank_file = TargRep::GenbankFile.new
          render :action => "new"
        }
        format.xml  { render :xml  => @allele.errors, :status => :unprocessable_entity }
        format.json { render :json => @allele.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /alleles/1
  # PUT /alleles/1.xml
  def update
    find_allele
    mutational_drop_downs

    respond_to do |format|
      if @allele.update_attributes(params[:targ_rep_allele])
        # Useful for all formats, not only HTML
        update_links_escell_to_targ_vec( @allele.id, params[:targ_rep_allele] )

        format.html {
          flash[:notice] = 'Allele successfully updated.'
          redirect_to @allele
        }
        format.xml  { render :xml  => @allele }
        format.json { render :json => @allele }
      else
        format.html {
          if @allele.genbank_file.nil?
            @allele.genbank_file = TargRep::GenbankFile.new
          end
          render :action => "edit"
        }
        format.xml  { render :xml   => @allele.errors, :status => :unprocessable_entity }
        format.json { render :json  => @allele.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /alleles/1
  # DELETE /alleles/1.xml
  def destroy
    find_allele
    ensure_creator_or_admin
    @allele.destroy
    mutational_drop_downs

    respond_to do |format|
      format.html { redirect_to :back }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

  ##
  ## Custom controllers
  ##

  # GET /alleles/1/escell_clone_genbank_file/
  def escell_clone_genbank_file
    find_allele
    return if check_for_genbank_file
    return if check_for_escell_genbank_file
    send_genbank_file(@allele.genbank_file.escell_clone)
  end

  # GET /alleles/1/targeting-vector-genbank-file/
  def targeting_vector_genbank_file
    find_allele
    return if check_for_genbank_file
    return if check_for_vector_genbank_file
    send_genbank_file(@allele.genbank_file.targeting_vector)
  end

  def escell_clone_cre_genbank_file
    find_allele
    return if check_for_genbank_file
    return if check_for_escell_genbank_file
    send_genbank_file(@allele.genbank_file.escell_clone_cre)
  end

  def targeting_vector_cre_genbank_file
    find_allele
    return if check_for_genbank_file
    return if check_for_vector_genbank_file
    send_genbank_file(@allele.genbank_file.targeting_vector_cre)
  end

  def escell_clone_flp_genbank_file
    find_allele
    return if check_for_genbank_file
    return if check_for_escell_genbank_file
    send_genbank_file(@allele.genbank_file.escell_clone_flp)
  end

  def targeting_vector_flp_genbank_file
    find_allele
    return if check_for_genbank_file
    return if check_for_vector_genbank_file
    send_genbank_file(@allele.genbank_file.targeting_vector_flp)
  end

  def escell_clone_flp_cre_genbank_file
    find_allele
    return if check_for_genbank_file
    return if check_for_escell_genbank_file
    send_genbank_file(@allele.genbank_file.escell_clone_flp_cre)
  end

  def targeting_vector_flp_cre_genbank_file
    find_allele
    return if check_for_genbank_file
    return if check_for_vector_genbank_file
    send_genbank_file(@allele.genbank_file.targeting_vector_flp_cre)
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

  # GET /alleles/1/allele-image/
  def allele_image
    find_allele
    return if check_for_genbank_file
    return if check_for_escell_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.escell_clone).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/allele-image-cre/
  def allele_image_cre
    find_allele
    return if check_for_genbank_file
    return if check_for_escell_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.escell_clone_cre).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/allele-image-flp/
  def allele_image_flp
    find_allele
    return if check_for_genbank_file
    return if check_for_escell_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.escell_clone_flp).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/allele-image-flp-cre/
  def allele_image_flp_cre
    find_allele
    return if check_for_genbank_file
    return if check_for_escell_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.escell_clone_flp_cre).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/cassette-image/
  def cassette_image
    find_allele
    return if check_for_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.escell_clone, true).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/vector-image/
  def vector_image
    find_allele
    return if check_for_genbank_file
    return if check_for_vector_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.targeting_vector ).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/vector-image-cre/
  def vector_image_cre
    find_allele
    return if check_for_genbank_file
    return if check_for_vector_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.targeting_vector_cre ).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/vector-image-flp/
  def vector_image_flp
    find_allele
    return if check_for_genbank_file
    return if check_for_vector_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.targeting_vector_flp ).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/vector-image-flp-cre/
  def vector_image_flp_cre
    find_allele
    return if check_for_genbank_file
    return if check_for_vector_genbank_file
    send_allele_image(AlleleImage::Image.new(@allele.genbank_file.targeting_vector_flp_cre ).render.to_blob { self.format = "PNG" })
  end

  def send_allele_image(allele_image)
    send_data(
      allele_image,
      {
        :disposition => "inline",
        :type => "image/png"
      }
    )
  end

  private
    def find_allele
      @allele = TargRep::Allele.find(params[:id])
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
        allele_params[:es_cells].each { |attrs| attrs[:nested] = true }
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

      ##
      ##  Genbank Files
      ##

      if allele_params.include? :genbank_file
        allele_params[:genbank_file].update({ :nested => true })
        allele_params[:genbank_file_attributes] = allele_params.delete(:genbank_file)
      end

      # Don't create genbank file object if its attributes are empty.
      gb_files_attrs = allele_params[:genbank_file_attributes]
      if gb_files_attrs
        gb_escell   = gb_files_attrs[:escell_clone]
        gb_targ_vec = gb_files_attrs[:targeting_vector]

        if ( gb_escell.nil? and gb_targ_vec.nil? ) or ( gb_escell.empty? and gb_targ_vec.empty? )
          allele_params.delete(:genbank_file_attributes)
        end
      end
    end

    def four_oh_four
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => "404 Not Found" }
        format.all { render :nothing => true, :status => "404 Not Found" }
      end
    end

    def check_for_genbank_file
      four_oh_four if @allele.genbank_file.nil?
    end

    def check_for_escell_genbank_file
      four_oh_four if @allele.genbank_file.escell_clone.nil? || @allele.genbank_file.escell_clone.empty?
    end

    def check_for_vector_genbank_file
      four_oh_four if check_for_genbank_file && @allele.genbank_file.targeting_vector.nil? || @allele.genbank_file.targeting_vector.empty?
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
            es_cell = TargRep::EsCell.find attrs[:id]
          else
            search  = TargRep::EsCell.search(:name_like => attrs[:name], :allele_id_is => allele_id).result
            es_cell = search.first
          end

          # Find targeting vector from given name and link it to the ES Cell
          if es_cell and es_cell.targeting_vector.nil?
            es_cell.targeting_vector = TargRep::TargetingVector.find_by_name!(attrs[:targeting_vector_name])
            es_cell.save
          end
        end
      end
    end
end
