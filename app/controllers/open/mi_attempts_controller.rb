# encoding: utf-8

class Open::MiAttemptsController < OpenApplicationController

  respond_to :html
  respond_to :json, :only => :index

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
      format.json {render :json => data_for_serialized(:json) }
    end
  end

  def show
    @mi_attempt = MiAttempt.find(params[:id])

    if @mi_attempt.report_to_public
      respond_with @mi_attempt
    else
      redirect_to open_mi_attempts_path,  :alert => "No mouse production exists with id #{params[:id]}."
    end
  end

  def data_for_serialized(format)
    super(format, 'id asc', MiAttempt, :public_search, false)
  end
  protected :data_for_serialized

end
