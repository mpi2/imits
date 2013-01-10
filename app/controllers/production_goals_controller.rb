class ProductionGoalsController < ApplicationController

  before_filter :authenticate_user!

    def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'consortia.name asc, year desc, month desc', ProductionGoal, :search)
      end

      format.html
    end
  end
end