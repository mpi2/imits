class SessionsController < Devise::SessionsController

  layout :layout_by_referer

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_navigational_format?

    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.any(*navigational_formats) { redirect_to redirect_path }
      format.all do
        head :no_content
      end
    end
  end

  private
    def redirect_path
      targ_rep? ? targ_rep_root_path : root_path
    end

    def layout_by_referer
      targ_rep? ? 'targ_rep' : 'application'
    end

    def targ_rep?
      request.referer =~ /targ_rep/
    end

end