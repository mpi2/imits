class OpenApplicationController < ApplicationController

  before_filter :set_report_to_public_flag

  def set_report_to_public_flag
    if params[:q] || params.has_key?('extended_response')
      params[:report_to_public_true] = true
    end
  end

end