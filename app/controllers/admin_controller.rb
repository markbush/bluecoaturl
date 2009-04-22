require 'pp'
class AdminController < ApplicationController

  layout "application"

  before_filter :authorize_admin, :except => [:category_image]
  before_filter :authorize,       :only   => [:category_image]

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(params[:category])
    if request.post? and @category.save
      redirect_to :action => :list
    else
      render :action => :new
    end
  end

  def edit
    begin
      @category = Category.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to edit invalid category: #{params[:id]}")
      flash[:notice] = "Invalid category"
      redirect_to :action => :list
    end
  end

  def update
    begin
      @category = Category.find(params[:id])
      if request.post? and @category.update_attributes(params[:category])
        flash[:notice] = "Category #{@category.name} updated"
        redirect_to :action => :list
      else
        render :action => :edit
      end
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to update invalid category: #{params[:id]}")
      flash[:notice] = "Invalid category"
      redirect_to :action => :list
    end
  end

  def index
    list
    render :action => :list
  end

  def list
    @all_categories = Category.find(:all, :order => :name)
#    @category_pages, @categories = paginate :categories, :order => :name
    @categories = Category.paginate :page => params[:page], :order => :name 
  end

  def category_image
    begin
      category = Category.find(params[:id])
      send_data(category.image, :filename => "#{category.name}.gif",
                                :type => 'image/gif',
                                :disposition => 'inline')
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to access invalid category: #{params[:id]}")
      render :nothing => true
    end
  end

  def destroy
    action = :list
    if request.post?
      begin
        category = Category.find(params[:id])
        if category.webaddresses.empty?
          category.destroy
          flash[:notice] = "Category #{category.name} deleted"
        else
          session[:category] = category.id
          action = :confirm_destroy
        end
      rescue ActiveRecord::RecordNotFound
        # ignore attempts to delete invalid entries - just log
        logger.error("Attempt to delete invalid category: #{params[:id]}")
      end
    end
    redirect_to :action => action
  end

  def confirm_destroy
    begin
      if request.post?
        category_id = params[:id]
        category = Category.find(params[:id])
        category.update_attribute(:webaddresses, [])
        category.destroy
        flash[:notice] = "Category #{category.name} deleted, removing URLs"
        redirect_to :action => :list
      else
        category_id = session[:category]
        session[:category] = nil
        @this_category = Category.find(category_id)
        @categories = Category.find(:all, :order => :name) - [@this_category]
        @webaddresses = @this_category.webaddresses
      end
    rescue ActiveRecord::RecordNotFound
      # ignore attempts to delete invalid entries - just log
      logger.error("Attempt to delete invalid category: #{category_id}")
      redirect_to :action => :list
    end
  end

  def confirm_destroy_with_move
    begin
      if request.post?
        category = Category.find(params[:id])
        new_category = Category.find(params[:new_category])
        new_category.webaddresses.push(category.webaddresses - new_category.webaddresses)
        category.update_attribute(:webaddresses, [])
        category.destroy
        flash[:notice] = "Deleted category #{category.name} moving URLs to category #{new_category.name}"
      end
    rescue ActiveRecord::RecordNotFound
      # ignore attempts to delete invalid entries - just log
      logger.error("Attempt to delete invalid category: #{params[:id]} moving to: #{params[:new_category]}")
    end
    redirect_to :action => :list
  end

  def move_urls
    begin
      if request.post?
        category = Category.find(params[:id])
        new_category = Category.find(params[:new_category])
        new_category.webaddresses.push(category.webaddresses - new_category.webaddresses)
        category.update_attribute(:webaddresses, [])
        flash[:notice] = "URLs moved from category #{category.name} to category #{new_category.name}"
      end
    rescue ActiveRecord::RecordNotFound
      # ignore attempts to delete invalid entries - just log
      logger.error("Invalid move from: #{params[:id]} to: #{params[:new_category]}")
    end
    redirect_to :action => :list
  end
end
