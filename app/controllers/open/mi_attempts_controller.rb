# encoding: utf-8

class Open::MiAttemptsController < ApplicationController

  respond_to :html

  def index
    respond_to do |format|
      format.html do
        set_centres_and_consortia
        q = params[:q] ||= {}

        q[:terms] ||= ''
        q[:terms] = q[:terms].lines.map(&:strip).select{|i|!i.blank?}.join("\n")
        @access = false
        render 'mi_attempts/index' # renders the apps/views/mi_attempts/index.html.erb view.
      end
    end
  end

  def show
    @mi_attempt = Public::MiAttempt.find(params[:id])
    if @mi_attempt.has_status?(:gtc) && @mi_attempt.distribution_centres.length == 0
      @mi_attempt.distribution_centres.build
    end

    respond_with @mi_attempt
  end

end
