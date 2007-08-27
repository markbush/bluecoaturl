class HostsController < ApplicationController
  
  layout "application"

  before_filter :authorize_admin,  :except => [:deploy, :deploy_to_hosts, :perform_deploy]
  before_filter :authorize_deploy, :only   => [:deploy, :deploy_to_hosts, :perform_deploy]
  filter_parameter_logging :password, :enable_password

  def index
    list
    render :action => :list
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update, :perform_deploy ],
         :redirect_to => { :action => :list }

  def list
    @hosts = Host.find(:all, :order => :hostname)
  end

  def new
    @host = Host.new
  end

  def create
    @host = Host.new(params[:host])
    if @host.save
      redirect_to :action => :list
    else
      render :action => :new
    end
  end

  def edit
    begin
      @host = Host.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to edit invalid host: #{params[:id]}")
      flash[:notice] = "Invalid host"
      redirect_to :action => :list
    end
  end

  def update
    begin
      @host = Host.find(params[:id])
      if @host.update_attributes(params[:host])
        flash[:notice] = 'Host #{@host.hostname} updated'
        redirect_to :action => :list
      else
        render :action => :edit
      end
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to update invalid host: #{params[:id]}")
      flash[:notice] = "Invalid host"
      redirect_to :action => :list
    end
  end

  def destroy
    begin
      host = Host.find(params[:id])
      host.destroy
      flash[:notice] = "Host #{host.hostname} deleted"
    rescue ActiveRecord::RecordNotFound
      # ignore attempts to delete invalid entries - just log
      logger.error("Attempt to delete invalid host: #{params[:id]}")
    end
    redirect_to :action => :list
  end
  
  def deploy
    @hosts = Host.find(:all, :order => :hostname)
  end
  
  def deploy_to_hosts
    if request.xhr?
      @hosts_to_update = params[:update].select {|id, update| update == '1'}.collect {|item| item[0]}
      @hosts = Host.find(:all)
    else
      redirect_to :action => :deploy
    end
  end

  def perform_deploy
    if request.xhr?
      begin
        host = Host.find(params[:id])
        host.deploy
        render :update do |page|
          if host.dirty?
            page["status_#{host.id}"].update('Failed')
            page["dirty_#{host.id}"].update('Yes')
          else
            page["status_#{host.id}"].update('Up to date')
            page["dirty_#{host.id}"].update('No')
          end
        end
      rescue Exception => e
        render :update do |page|
          page["status_#{params[:id]}"].update('Failed')
        end
      end
    else
      redirect_to :action => :deploy
    end
  end
end
