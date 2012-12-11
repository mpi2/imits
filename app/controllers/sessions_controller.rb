class SessionsController < Devise::SessionsController

  layout :layout_by_referer

  private

    def layout_by_referer
      targ_rep? ? 'targ_rep' : 'application'
    end

    def targ_rep?
      request.env['HTTP_REFERER'] =~ /targ_rep/
    end

end