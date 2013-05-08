class DistributionCentresController < ApplicationController

  before_filter :find_class

  def index
    ## Defined in app/reports/distribution_management_report.rb
    @report = DistributionManagementReport.new(@klass)

    respond_to do |format|
      format.html {
        render :template => 'distribution_centres/index'
      } 
    end
  end

  def new
    @distribution_centre = @klass.new
  end

  def show
    find_distribution_centre
  end

  def create
    @distribution_centre = @klass.new(params[@klass.table_name.to_sym])

    if @distribution_centre.save
      redirect_to [@klass.table_name.to_sym], :notice => "Your distribution centre was created successfully."      
    else
      render :action => 'new'
    end
  end

  def update
    find_distribution_centre

    if @distribution_centre.update_attributes(params[@klass.table_name.to_sym])
      redirect_to [@klass.table_name.to_sym], :notice => "Your distribution centre was updated successfully."
    else
      flash.now[:alert] = "Could not update distribution centre."
      render :action => 'show'
    end
  end

  def grid_redirect
    mis = @klass.parent
      .includes(
        :distribution_centres => [:centre],
        :mi_plan => [:consortium, :production_centre])
      .where('consortia.name = ?', params[:consortium_name])
      .where('production_centres_mi_plans.name = ?', params[:pc_name])
      .where('mi_plan_id = mi_plans.id')
      .where("#{@klass.parent.table_name}.status_id in (?)", @status_id)

    if params[:dc_name].blank?
      mis = mis.where('centres is null')
    else
      mis = mis.where('centres.name = ?', params[:dc_name])

      if params[:distribution_network].blank?
        mis = mis.where("#{@klass.table_name}.distribution_network is null")
      else
        mis = mis.where("#{@klass.table_name}.distribution_network = ?", params[:distribution_network])
      end  

    end

    if mis.count > 50
      mis = mis.limit(50)
      @flash = "Report limited to 50 records."
    end

    if @klass.parent.table_name == 'mi_attempts'
      redirect_to mi_attempts_path('q[mi_attempt_id]' => mis.map(&:id).join(',')), :alert => @flash
    else
      redirect_to phenotype_attempts_path('q[phenotype_attempt_id]' => mis.map(&:id).join(',')), :alert => @flash
    end
  end

  def history
    @resource = @klass.find(params[:id])
    render :template => '/shared/history'
  end

  def find_class
    #
    # Look in mi_attempt/distribution_centres_controller.rb for this to work.
    # You need to define @klass and @table_name. For example:
    # @klass = MiAttempt::DistributionCentre
    # @status_id = 2
    #
    raise "You need to extend this method & controller for this to work."
  end

  private
    def find_distribution_centre
      @distribution_centre = @klass.find_by_id!(params[:id])
    end

end