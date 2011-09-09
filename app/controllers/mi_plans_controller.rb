# encoding: utf-8

class MiPlansController < ApplicationController
  respond_to :html
  before_filter :authenticate_user!

  def gene_selection
    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
      q[:marker_symbol_or_mgi_accession_id_ci_in]
        .lines
        .map(&:strip)
        .select{|i|!i.blank?}
        .join("\n")
  end

end
