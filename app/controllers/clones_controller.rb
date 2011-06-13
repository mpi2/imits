# encoding: utf-8

class ClonesController < ApplicationController
  respond_to :xml, :json

  def show
    @clone = Clone.find(params[:id])
    respond_with @clone
  end

  def index
    @clones = Clone.search(cleaned_params).all
    respond_with @clones
  end

end
