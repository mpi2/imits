# encoding: utf-8

class Open::PhenotypeAttemptsController < OpenApplicationController

  respond_to :html, :json
  respond_to :json, :only => :index

  def index
    respond_to do |format|
      set_centres_and_consortia
      format.html do
        q = params[:q] ||= {}

        q[:terms] ||= ''
        q[:terms] = q[:terms].lines.map(&:strip).select{|i|!i.blank?}.join("\n")
        @access = false
        render 'phenotype_attempts/index' # renders the apps/views/phenotype_attempts/index.html.erb view.
      end

      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def show
    @phenotype_attempt = Public::PhenotypeAttempt.find(params[:id])

    if @phenotype_attempt.report_to_public
      @mi_attempt = @phenotype_attempt.mi_attempt
      respond_with @phenotype_attempt
    else
      redirect_to open_phenotype_attempts_path,  :alert => "No mouse phenotyping exists with id #{params[:id]}."
    end
  end

  def data_for_serialized(format)
    super(format, 'id asc', Public::PhenotypeAttempt, :public_search, false)
  end
  protected :data_for_serialized
end
