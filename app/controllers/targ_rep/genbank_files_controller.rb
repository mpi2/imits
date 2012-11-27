class TargRep::GenbankFilesController < TargRep::BaseController
  
  respond_to :xml, :json
  
  before_filter :authorize_admin_user!, :only => :destroy

  def index
    respond_to do |format|
      if params.key? :allele_id
        @genbank_file = TargRep::GenbankFile.search(:allele_id_eq => params[:allele_id]).result.all
        format.xml  { render :xml   => @genbank_file }
        format.json { render :json  => @genbank_file }
      else
        errors = { :allele_id => "is required" }
        format.xml  { render :xml   => errors, :status => :unprocessable_entity }
        format.json { render :json  => errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def show
    find_genbank_file
    respond_with @genbank_file
  end

  def create
    @genbank_file = TargRep::GenbankFile.new(params[:targ_rep_genbank_file])

    respond_to do |format|
      if @genbank_file.save
        format.xml  { render :xml  => @genbank_file, :status => :created, :location => @genbank_file }
        format.json { render :json => @genbank_file, :status => :created, :location => @genbank_file }
      else
        format.xml  { render :xml  => @genbank_file.errors, :status => :unprocessable_entity }
        format.json { render :json => @genbank_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    find_genbank_file

    respond_to do |format|
      if @genbank_file.update_attributes(params[:targ_rep_genbank_file])
        format.xml  { render :xml  => { :id => @genbank_file.id }, :location => @genbank_file }
        format.json { render :json => { :id => @genbank_file.id }, :location => @genbank_file }
      else
        format.xml  { render :xml  => @genbank_file.errors, :status => :unprocessable_entity }
        format.json { render :json => @genbank_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    find_genbank_file

    @genbank_file.destroy

    respond_to do |format|
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

  private
    def find_genbank_file
      @genbank_file = TargRep::GenbankFile.find(params[:id])
    end
end
