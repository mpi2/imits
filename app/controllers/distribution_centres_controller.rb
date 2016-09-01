class DistributionCentresController < ApplicationController

  before_filter :find_class

  def index
    ## Defined in app/reports/distribution_management_report.rb
    @report = DistributionManagementReport.new(@model_table_name)

    respond_to do |format|
      format.html {
        render :template => 'distribution_centres/index'
      }
    end
  end

  def new
    @distribution_centre = Colony::DistibutionCentre.new
  end

  def show
    find_distribution_centre
  end

#  def create
#    @distribution_centre = Colony::DistibutionCentre.new(params[@model_table_name.to_sym])

#    if @distribution_centre.save
#      redirect_to [@klass.table_name.to_sym], :notice => "Your distribution centre was created successfully."
#    else
#      render :action => 'new'
#    end
#  end

#  def update
#    find_distribution_centre

#    if @distribution_centre.update_attributes(params[@klass.table_name.to_sym])
#      redirect_to [@klass.table_name.to_sym], :notice => "Your distribution centre was updated successfully."
#    else
#      flash.now[:alert] = "Could not update distribution centre."
#      render :action => 'show'
#    end
#  end

  def grid_redirect
    col = Colony.find_by_sql(
       <<-EOF
        SELECT colonies.*
        FROM colonies
          JOIN colony_distribution_centres cdc ON cdc.colony_id = colonies.id
          JOIN centres dc ON dc.id = cdc.centre_id
          JOIN #{@model_table_name} ON colonies.#{@model_table_name.singularize}_id = #{@model_table_name}.id
          JOIN plans ON plans.id = #{@model_table_name}.plan_id
          JOIN centres ON centres.id = plans.production_centre_id
          JOIN consortia ON consortia.id = plans.consortium_id
        WHERE consortia.name = '#{params[:consortium_name]}'
          AND centres.name = '#{params[:pc_name]}'
          AND #{@model_table_name}.status_id IN (#{@status_id.join(',')})
          #{ params[:dc_name].blank? ? "AND dc.name IS NULL" : "AND dc.name = '#{params[:dc_name]}'" }
          #{ params[:distribution_network].blank? ? "AND cdc.distribution_network IS NULL" : "AND cdc.distribution_network = '#{params[:distribution_network]}'" }
        LIMIT 50
        EOF
       )

    if col.count == 50
      @flash = "Report limited to 50 records."
    end

    if @model_table_name == 'mi_attempts'
      redirect_to mi_attempts_path('q[mi_attempt_id]' => col.map(&:mi_attempt_id).join(',')), :alert => @flash
    else
      redirect_to mi_attempts_path('q[phenotype_attempt_id]' => col.map{ |c|c.mouse_allele_mod.phenotype_attempt_id}.join(',') ).gsub('mi_attempts', 'phenotype_attempts'), :alert => @flash
    end
  end

  def history
    @resource = Colony::DistributionCentre.find(params[:id])
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
      @distribution_centre = Colony::DistributionCentre.find_by_id!(params[:id])
    end

end