class DistributionCentresController < ApplicationController

  before_filter :find_class

  def index
    @distribution_centres = @klass.all
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
    @distribution_centre = @klass.new(params[@table_name.to_sym])

    if @distribution_centre.save
      redirect_to [@table_name.to_sym], :notice => "Your distribution centre was created successfully."      
    else
      render :action => 'new'
    end
  end

  def update
    find_distribution_centre

    if @distribution_centre.update_attributes(params[@table_name.to_sym])
      redirect_to [@table_name.to_sym], :notice => "Your distribution centre was updated successfully."
    else
      flash.now[:alert] = "Could not update distribution centre."
      render :action => 'show'
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
    # @table_name = 'mi_attempt_distribution_centres'
    #
    raise "You need to extend this method & controller for this to work."
  end

  private
    def find_distribution_centre
      @distribution_centre = @klass.find_by_id!(params[:id])
    end

end