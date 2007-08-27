class UrlController < ApplicationController

  layout "application"

  before_filter :authorize,       :except => [:downloadurllist];
  before_filter :authorize_admin, :only   => [:list_orphaned, :purge, :download, :upload]

  def new
    @webaddress = Webaddress.new
    @webaddress.path = "/"
    @categories = Category.find(:all, :order => :name).collect {|c| [c.name, c.id]}
    @selected = []
  end

  def create
    action = :new
    @webaddress = Webaddress.new(params[:webaddress])
    @webaddress.user_id = session[:user_id]
    if request.post?
      if params[:confirm] && (params[:confirm].to_i == 1)
        existing = false
      else
        existing = @webaddress.check_address(self)
      end
      if ! existing && @webaddress.save
        redirect_to :action => :list
      else
        @categories = Category.find(:all, :order => :name).collect {|c| [c.name, c.id]}
        @selected = @webaddress.categories.collect {|c| c.id.to_i }
        action = :confirm if existing
        render :action => action
      end
    else
      redirect_to :action => action
    end
  end

  def edit
    begin
      @webaddress = Webaddress.find(params[:id])
      @categories = Category.find(:all, :order => :name).collect {|c| [c.name, c.id]}
      @selected = @webaddress.categories.collect {|c| c.id.to_i }
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to edit invalid url: #{params[:id]}")
      flash[:notice] = "Invalid URL"
      redirect_to :action => :list
    end
  end

  def update
    begin
      @webaddress = Webaddress.find(params[:id])
      @webaddress.user_id = session[:user_id]
      if request.post? and params[:webaddress] and @webaddress.update_attributes(params[:webaddress])
        flash[:notice] = "URL #{@webaddress.address} updated"
        redirect_to :action => :list
      else
        @categories = Category.find(:all, :order => :name).collect {|c| [c.name, c.id]}
        @selected = @webaddress.categories.collect {|c| c.id.to_i }
        render :action => :edit
      end
    rescue ActiveRecord::RecordNotFound
      logger.error("Attempt to update invalid url: #{params[:id]}")
      flash[:notice] = "Invalid URL"
      redirect_to :action => :list
    end
  end

  def destroy
    if request.post?
      begin
        webaddress = Webaddress.find(params[:id])
        if category = webaddress.categories.find(params[:category])
          webaddress.categories.delete(category)
          flash[:notice] = "URL removed from category #{category.name}"
        else
          flash[:notice] = "URL #{params[:id]} not in category #{category.name}"
        end
      rescue ActiveRecord::RecordNotFound
        # ignore attempts to delete invalid entries - just log
        logger.error("Attempt to delete invalid url: #{params[:id]} from category: #{category.name}")
      end
    end
    redirect_to :action => :list
  end

  def index
    list
    render :action => :list
  end

  def list
    @selected = -1
    if params[:sort] and ! params[:sort].eql?('site')
      begin
        category = Category.find(params[:sort])
        @selected = category.id
        @webaddresses = category.webaddresses
        others = Webaddress.find(:all, :order => :site) - @webaddresses
        @webaddresses += others
      rescue ActiveRecord::RecordNotFound
        @webaddresses = Webaddress.find(:all, :order => :site).select {|w| !w.categories.empty?}
      end
    else
      @webaddresses = Webaddress.find(:all, :order => :site).select {|w| !w.categories.empty?}
    end
    @all_categories = Category.find(:all, :order => :name)
    @categories = @all_categories.dup
    if params[:search_categories].instance_of?(String)
      logger.debug("search_categories from: #{params[:search_categories].inspect}")
      params[:search_categories] = params[:search_categories].split(%r{/})
      logger.debug("search_categories to: #{params[:search_categories].inspect}")
    end
    if params[:search_categories] && params[:search_categories].length > 0
      @categories.delete_if {|c| !params[:search_categories].include?(c.id.to_s)}
    else
      params[:search_categories] = []
    end
    if params[:search_url] && params[:search_url].length > 0
      u_str = params[:search_url]
      unless u_str.match(/[\\\*\+\(\)\[\]]/)
        u_str = u_str.gsub(/\./, '\\.')
      end
      u_re = Regexp.new(u_str, true)
      @webaddresses.delete_if {|w| !u_re.match(w.address)}
    end
    if params[:urls_in_category] && params[:urls_in_category].to_s == '1'
      @webaddresses.delete_if {|w| (w.categories - @categories).length == w.categories.count}
    end
    # Generate paginator for the list (@webaddresses)
    page = (params[:page] ||= 1).to_i
    items_per_page = 20
    offset = (page - 1) * items_per_page
    @webaddress_pages = Paginator.new(self, @webaddresses.length, items_per_page, page)
    @webaddresses = @webaddresses[offset..(offset + items_per_page - 1)]
  end

  def download_setup
    @categories = Category.find(:all, :order => :name)
    @webaddresses = Webaddress.find(:all).select {|w| !w.categories.empty?}
  end

  def download
    download_setup
    render :layout => false
    send_data response.body, :filename => 'URL-list'
  end

  def downloadurllist
    download_setup
    render :action => :download, :layout => false
  end

  def upload
    if request.post?
      logger.debug(params[:data])
      category = nil
      c = nil
      count = 0
      params[:data].split(/[\r\n]+/).each do |line|
        if line.match(/^\s*end\s*$/)
          category = nil
        elsif line.match(/^\s*define\s+category\s+([A-Za-z0-9_]+)\s*$/)
          category = $1
          c = Category.find_by_name(category)
          unless c
            c = Category.create(:name => category, :description => "Initial Import")
            count += 1
          end
        elsif line.match(/^\s*(\S+)\s*$/)
          url = $1
          url.sub!(%r{https?://}i, '')
          parts = url.split(%r{/})
          site = parts.shift
          path = "/"+parts.join("/")
          w = Webaddress.new(:site => site, :path => path,
                             :reason => "Initial Import", :user_id => session[:user_id])
          w.categories.push(c)
          w.save
          count += 1
        end
      end
      if count > 0
        flash[:notice] = "Data successfully loaded" if (count > 0)
        redirect_to :controller => :admin, :action => :list
      end
    end
  end

  def list_orphaned
    @webaddresses = Webaddress.find(:all, :order => :site).select {|w| w.categories.empty?}
  end

  def purge
    if request.post?
      Webaddress.find(:all).select {|w| w.destroy if w.categories.empty?}
      flash[:notice] = "Orphan URLs purged"
    end
    redirect_to :action => :list
  end

  def toggle_url
    if request.post?
      Category.find(:all).each do |c|
        begin
          webaddresses = Webaddress.find(params[:url][c.id.to_s])
          webaddresses = [] if webaddresses.nil?
          c.update_attribute(:webaddresses, webaddresses)
        rescue ActiveRecord::RecordNotFound
          c.update_attribute(:webaddresses, [])
        end
      end
    end
    render :nothing => true
  end

  def add_association
    if request.post?
      begin
        ids = params[:id].split(/-/)
        webaddress = Webaddress.find(ids[0])
        category = Category.find(ids[1])
        unless category.webaddresses.include?(webaddress)
          category.webaddresses.push(webaddress)
        end
        render :partial => 'toggle_link', :locals => {:webaddress => webaddress, :category => category}
      rescue ActiveRecord::RecordNotFound
        logger.error("Attempt to add invalid association: #{params[:id]}")
        redirect_to :action => :list
      end
    end
  end

  def remove_association
    if request.post?
      begin
        ids = params[:id].split(/-/)
        webaddress = Webaddress.find(ids[0])
        category = Category.find(ids[1])
        category.webaddresses.delete(webaddress)
        render :partial => 'toggle_link', :locals => {:webaddress => webaddress, :category => category}
      rescue ActiveRecord::RecordNotFound
        logger.error("Attempt to remove invalid association: #{params[:id]}")
        redirect_to :action => :list
      end
    end
  end
end
