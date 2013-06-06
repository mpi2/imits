class TrackingGoalsController < ApplicationController

  respond_to :json
  respond_to :html, :only => [:index]

  before_filter :authenticate_user!

    def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'production_centre_id asc, date desc', TrackingGoal, :search)
      end

      format.html
    end
  end

  def show
    redirect_to [:tracking_goals]
  end

  def create
    @tracking_goal = TrackingGoal.new(params[:tracking_goal])

    if @tracking_goal.save
      respond_with @tracking_goal
    else
      render :json => {'error' => 'Could not create tracking goal (invalid data)'}, :status => 422
    end
  end

  def update
    @tracking_goal = TrackingGoal.find(params[:id])
    
    respond_to do |format|
      if @tracking_goal.update_attributes(params[:tracking_goal])
        format.json { render :json => @tracking_goal.to_json }
      else
        format.json { render :json => {'error' => 'Could not update tracking goal (invalid data)'}, :status => 422 }
      end
    end
  end

  def destroy
    @tracking_goal = TrackingGoal.find(params[:id])

    @tracking_goal.destroy

    respond_to do |format|
      format.html { redirect_to [:tracking_goals]}
      format.json { render :nothing => true, :status => 200 }
    end
  end

  def history
    @resource = TrackingGoal.find(params[:id])
    render :template => '/shared/history'
  end
end