# encoding: utf-8

class Open::MiPlansController < OpenApplicationController
  respond_to :html, :only => [:gene_selection, :index]
  respond_to :json, :except => [:gene_selection, :index]

  def gene_selection

    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
            q[:marker_symbol_or_mgi_accession_id_ci_in].
            lines.map(&:strip).select{|i|!i.blank?}.join("\n")
    @access = false
    render 'mi_plans/gene_selection' # renders the apps/views/mi_plans/selection.html.erb view.
  end

#  def show
#    set_centres_and_consortia
#    @mi_plan = Public::MiPlan.find_by_id(params[:id])
#    respond_with @mi_plan
#  end

  def index
    respond_to do |format|
      format.html do
        set_centres_and_consortia
        @access = false
        render 'mi_plans/index' # renders the apps/views/mi_plans/index.html.erb view.
      end

      format.json do
        render :json => data_for_serialized(:json, 'marker_symbol asc', Public::MiPlan, :public_search, false)
      end
    end
  end

end
