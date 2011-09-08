# encoding: utf-8

class MiPlansController < ApplicationController
  respond_to :html

  before_filter :authenticate_user!

  def gene_selection
    if !params[:q].blank? && !params[:q][:marker_symbol_or_mgi_accession_id_ci_in].blank?
      params[:q][:marker_symbol_or_mgi_accession_id_ci_in] =
        params[:q][:marker_symbol_or_mgi_accession_id_ci_in].lines.collect(&:strip)
    end

    @q = Gene.search(params[:q])
    @genes = []

    if !params[:q].blank? && !params[:q][:marker_symbol_or_mgi_accession_id_ci_in].blank?
      @genes = @q.result(:distinct => true).order("marker_symbol asc")
    end
  end

end
