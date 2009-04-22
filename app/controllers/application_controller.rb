# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_bluecoat_session_id'

  include ExceptionNotifiable


  def make_link(w)
    "<a href=\"" + url_for(:controller => :url, :action => :edit, :id => w.id) +
             "\">" + w.site + "</a>"
  end

  private

  def authorize
    unless User.find_by_id(session[:user_id], :conditions => ["enabled = ?", true])
      session[:original_uri] = request.request_uri
      flash[:notice] = "Please log in"
      redirect_to :controller => :login, :action => :login
      return false
    end
  end

  def authorize_admin
    unless User.find_by_id(session[:user_id], :conditions => ["enabled = ? and admin = ?", true, true])
      redirect_to :controller => :url, :action => :list
      return false
    end
  end

  def authorize_deploy
    unless User.find_by_id(session[:user_id],
                           :conditions => ["enabled = ? and (admin = ? or can_deploy = ?)", true, true, true])
      redirect_to :controller => :url, :action => :list
      return false
    end
  end
end
