class RootController < ApplicationController

  respond_to :html

  before_filter :authenticate_user!

  def index
  end
end
