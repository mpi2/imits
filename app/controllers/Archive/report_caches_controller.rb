# encoding: utf-8

class ReportCachesController < ApplicationController
  respond_to :csv
  before_filter :authenticate_user!

  def show
    cache = ReportCache.find_by_name_and_format(params[:id], 'csv')
    if cache
      response.headers['Content-Disposition'] =
              "attachment; filename=#{cache.name}-#{cache.compact_timestamp}.csv"
      response.headers['Content-Length'] = cache.data.size.to_s
      render :csv => cache.data
    else
      render :csv => '', :status => 404
    end
  end
end
