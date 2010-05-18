class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'
  
  def set_mime_type_html
    response.headers['Content-type'] = 'text/html; charset=utf-8'
  end
  
  def render_html_with_flash(args)
    @flash_results = true
    set_mime_type_html  # Rails will return text/javscript type by default, and javascript will try and eval this HTML and raise an error
    render args
  end
  
  # unobtrustive link_to_remote, by default has a # in the href
  class ActionView::Base
    def link_to_remote(name, options = {}, html_options = {})  
      html_options.merge!({:href => url_for(options[:url])}) unless options[:url].blank?  
      super(name, options, html_options)  
    end
  end
end
