class LoginController < ApplicationController

  layout "application"

  before_filter :authorize_admin, :except => [:login, :logout, :change_password, :update_password, :blank]
  before_filter :authorize,       :only   => [:change_password, :update_password]
  filter_parameter_logging :password

  def new
    @user = User.new
    @password_label = "Password:"
  end

  def create
    @user = User.new(params[:user])
    @user.admin = params[:user][:admin]
    if request.post? and @user.save
      redirect_to :action => :list
    else
      render :action => :new
    end
  end

  def edit
    begin
      @user = User.find(params[:id])
      @password_label = "Password:"
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to edit invalid user: #{params[:id]}")
      flash[:notice] = "Invalid user"
      redirect_to :action => :list
    end
  end

  def update
    begin
      @user = User.find(params[:id])
      if request.post? and @user.update_attributes(params[:user]) and @user.update_attribute(:admin, params[:user][:admin])
        flash[:notice] = "User #{@user.name} updated"
        redirect_to :action => :list
      else
        @password_label = "Password:"
        render :action => :edit
      end
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to update invalid user: #{params[:id]}")
      flash[:notice] = "Invalid user"
      redirect_to :action => :list
    end
  end

  def destroy
    if request.post?
      if User.count(:conditions => ["enabled = ? and admin = ?", true, true]) < 2
        # Don't allow disable of last admin user
        flash[:notice] = "Can't delete last admin user!"
      else
        begin
          user = User.find(params[:id])
          user.enabled = false
          if user.save
            flash[:notice] = "User #{user.name} deleted"
          end
        rescue ActiveRecord::RecordNotFound
          # ignore attempts to delete invalid entries - just log
          logger.error("Attempt to delete invalid user: #{params[:id]}")
        end
      end
    end
    redirect_to :action => :list
  end

  def activate
    if request.post?
      begin
        user = User.find(params[:id])
        user.enabled = true
        if user.save
          flash[:notice] = "User #{user.name} activated"
        end
      rescue ActiveRecord::RecordNotFound
        # ignore attempts to delete invalid entries - just log
        logger.error("Attempt to activate invalid user: #{params[:id]}")
      end
    end
    redirect_to :action => :list
  end

  def index
    list
    render :action => :list
  end

  def list
    @active_users = User.find(:all, :conditions => ["enabled = ?", true])
    @inactive_users = User.find(:all, :conditions => ["enabled = ?", false])
  end

  def login
    reset_session
    username = request.env['HTTP_X_ISRW_PROXY_AUTH_USER']
    if username
      username.sub!(/.*\\/, '')
      user = User.find_by_name(username)
      logger.info("Pre-authenticated user: #{username}") if user
    end
    if request.post?
      user = User.authenticate(params[:name], params[:password])
    end
    if user
      session[:user_id] = user.id
      session[:user_name] = user.name
      session[:user_admin] = user.admin?
      session[:user_can_deploy] = user.can_deploy?
      uri = session[:original_uri]
      session[:original_uri] = nil
      if user.admin?
        redirect_to(uri || {:controller => :admin, :action => :list})
      else
        redirect_to(uri || {:controller => :url, :action => :list})
      end
    elsif request.post?
      flash[:notice] = "Invalid user/password combination"
    end
  end

  def login_form
    render :action => :login
  end

  def logout
    reset_session
    redirect_to :action => :login
  end

  def change_password
    @password_label = "New:"
  end

  def update_password
    begin
      @user = User.find(session[:user_id])
      if request.post?
        if @user.authenticate(params[:user][:old_password])
          if params[:user][:password].eql?(params[:user][:old_password])
            flash[:notice] = "New password must be different to old password!"
            redirect_to :action => :change_password
          elsif @user.update_attributes(params[:user])
            flash[:notice] = "Password changed for #{@user.name}"
            redirect_to :action => :blank
          else
            @password_label = "New:"
            render :action => :change_password
          end
        else
          flash[:notice] = "Old password invalid!"
          redirect_to :action => :change_password
        end
      else
        @password_label = "New:"
        render :action => :change_password
      end
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to update invalid user: #{params[:id]}")
      flash[:notice] = "Invalid user"
      redirect_to :action => :blank
    rescue Exception => e
      logger.error("Error updating password for id: #{session[:user_id]}: #{e.message}")
      flash[:notice] = "Error updating password"
      redirect_to :action => :blank
    end
  end

  def blank
  end
end
