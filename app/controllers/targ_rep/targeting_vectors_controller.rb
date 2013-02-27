class TargRep::TargetingVectorsController < TargRep::BaseController

  before_filter :authorize_admin_user!, :only => :destroy
  
  respond_to :xml, :json

  def index
    find_targeting_vectors

    @targeting_vectors = @search
    
    respond_to do |format|
      format.js # index.js.erb
      format.xml  { render :xml   => @targeting_vectors }
      format.json { render :json  => @targeting_vectors }
    end
  end

  def show
    find_targ_vec

    respond_with @targeting_vector
  end

  def create
    format_nested_params

    @targeting_vector = TargRep::TargetingVector.new(params[:targ_rep_targeting_vector])
    
    respond_to do |format|
      if @targeting_vector.save
        format.xml  { render :xml  => @targeting_vector, :status => :created, :location => @targeting_vector }
        format.json { render :json => @targeting_vector, :status => :created, :location => @targeting_vector }
      else
        format.xml  { render :xml  => @targeting_vector.errors, :status => 400, :location => @targeting_vector }
        format.json { render :json => @targeting_vector.errors, :status => 400, :location => @targeting_vector }
      end
    end
  end

  def update
    find_targ_vec
    format_nested_params

    respond_to do |format|
      if @targeting_vector.update_attributes(params[:targ_rep_targeting_vector])
        format.xml  { render :xml  => @targeting_vector, :status => :ok, :location => @targeting_vector }
        format.json { render :json => @targeting_vector, :status => :ok, :location => @targeting_vector }
      else
        format.xml  { render :xml  => @targeting_vector.errors, :status => :unprocessable_entity }
        format.json { render :json => @targeting_vector.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    find_targ_vec

    @targeting_vector.destroy

    respond_to do |format|
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
  
  private
    def find_targ_vec
      @targeting_vector = TargRep::TargetingVector.find(params[:id])
    end
    
    def find_targeting_vectors
      targ_vec_params = params.dup
      
      # Just keep TargetingVector params.
      targ_vec_params.delete "controller"
      targ_vec_params.delete "action"
      targ_vec_params.delete "format"
      targ_vec_params.delete "page"
      targ_vec_params.delete "per_page"
      targ_vec_params.delete "utf8"

      
      @search = TargRep::TargetingVector.search(targ_vec_params).result
    end
    
    def format_nested_params
      # Specific to create/update methods - webservice interface
      params[:targ_rep_targeting_vector] = params.delete(:targeting_vector) if params[:targeting_vector]
      targ_vec_params = params[:targ_rep_targeting_vector]
      
      # README: http://github.com/dazoakley/targ_rep2/issues#issue/1
      #
      # ``accepts_nested_attributes_for`` (in model.rb) expects 
      # es_cell_attributes as a key in params hash in order to 
      # create ES cell objects.
      # For now, it is allowed to send a nested Array such as ``es_cells``
      # instead of the expected ``es_cell_attributes`` Array.
      # This function will rename/move ``es_cells`` to ``es_cell_attributes``.
      #
      # Because of the rails issue (see ticket):
      # This function will also add the ``nested => true`` key/value pair to each
      # hash contained in the Array so that the model does not try to validate
      # the ES Cell before the targeting vector gets its ID (creation only).
      
      if targ_vec_params.include? :es_cells
        targ_vec_params[:es_cells].each { |attrs| attrs[:nested] = true }
        targ_vec_params[:es_cells_attributes] = targ_vec_params.delete(:es_cells)
      elsif not targ_vec_params.include? :es_cells_attributes
        targ_vec_params[:es_cells_attributes] = []
      end
    end
end
