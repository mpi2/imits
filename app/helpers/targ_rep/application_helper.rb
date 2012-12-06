module TargRep::ApplicationHelper

  def print_dash_on_empty( arg )
    if [nil,''].include?(arg)
      return '-'
    else
      return arg
    end
  end
  
  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files.map {|f| "targ_rep/#{f}"}) }
  end
  
  def stylesheet(*files)
    content_for(:head) { stylesheet_link_tag(*files.map {|f| "targ_rep/#{f}"}) }
  end

end