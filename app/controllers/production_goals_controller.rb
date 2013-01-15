class ProductionGoalsController < ApplicationController

  respond_to :json
  respond_to :html, :only => [:index]

  before_filter :authenticate_user!

    def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'consortium_id asc, year desc, month desc', ProductionGoal, :search)
      end

      format.html
    end
  end

  def create
    @production_goal = ProductionGoal.new(params[:production_goal])

    if @production_goal.save
      respond_with @production_goal
    else
      render :json => {'error' => 'Could not create production goal (invalid data)'}, :status => 422
    end

  end

  def update
    @production_goal = ProductionGoal.find(params[:id])
    
    respond_to do |format|
      if @production_goal.update_attributes(params[:production_goal])
        format.json { respond_with @production_goal }
      else
        format.json { render :json => {'error' => 'Could not update production goal (invalid data)'}, :status => 422 }
      end
    end
  end

  def destroy
    @production_goal = ProductionGoal.find(params[:id])

    @production_goal.destroy

    respond_to do |format|
      format.html { redirect_to [:production_goals]}
      format.json { render :nothing => true, :status => 200 }
    end
  end
end