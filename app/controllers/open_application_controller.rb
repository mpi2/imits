class OpenApplicationController < ApplicationController

  before_filter :set_report_to_public_flag

  def set_report_to_public_flag
    if params[:q]
      params[:report_to_public_eq] = false
    end
  end

end