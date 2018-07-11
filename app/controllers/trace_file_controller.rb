class TraceFileController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!, :except => [:show]

  def show
    id = params[:id]
    return if ! id

    trace_file = TraceFile.find_by_id(id)
    return if trace_file.nil?

    send_data(trace_file.trace.file_contents, :filename => trace_file.trace_file_name, :disposition => 'attachment') if !trace_file.trace_file_name.blank?
    return
  end

end
