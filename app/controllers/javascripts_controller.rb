class JavascriptsController < ActionController::Base

  def dynamic_esc_qc_conflict_selects
    respond_to do |format|
      format.js {render :content_type => 'text/javascript'}
    end
  end

end
