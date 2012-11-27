class TargRep::PipelinesController < TargRep::BaseController

  respond_to :html, :xml, :json

  def index
    @pipelines = TargRep::Pipeline.all
    
    respond_with @pipelines
  end

  def show
    find_pipeline

    respond_with @pipeline
  end

  def new
    @pipeline = TargRep::Pipeline.new

    respond_with @pipeline
  end

  def edit
    find_pipeline
  end

  def create
    @pipeline = TargRep::Pipeline.new(params[:targ_rep_pipeline])

    respond_to do |format|
      if @pipeline.save
        flash[:notice] = 'Pipeline was successfully created.'
        format.html { redirect_to(@pipeline) }
        format.xml  { render :xml => @pipeline, :status => :created, :location => @pipeline }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @pipeline.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    find_pipeline

    respond_to do |format|
      if @pipeline.update_attributes(params[:targ_rep_pipeline])
        flash[:notice] = 'Pipeline was successfully updated.'
        format.html { redirect_to(@pipeline) }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml  => @pipeline.errors, :status => :unprocessable_entity }
        format.json { render :json => @pipeline.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    find_pipeline

    @pipeline.destroy

    respond_to do |format|
      format.html { redirect_to([:targ_rep, :pipelines]) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
  
  private
  def find_pipeline
    @pipeline = TargRep::Pipeline.find(params[:id])
  end
end
