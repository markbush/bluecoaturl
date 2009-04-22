class Webaddress < ActiveRecord::Base

  has_and_belongs_to_many :categories, :order => :name
  has_many                :histories, :order => "created_at desc"

  validates_presence_of   :site
  validates_presence_of   :path
  validates_format_of     :site,       :with => %r{^[^/\s]*$}, :message => "must just be site name with no path and no white space"
  validates_format_of     :site,       :with => %r{\S\.\S},    :message => "must not be a top level domain"
  validates_format_of     :path,       :with => %r{^/[^\s?]*$}

  after_save              :update_hosts
  after_destroy           :update_hosts

  def before_validation
    self.site.sub!(%r{https?://}i, '')
    self.site.sub!(%r{^\*\.?}, '')
    self.site.sub!(%r{/$}, '')
  end

  def after_validation
    if self.categories.size == 0
      self.errors.add(:category_ids, "must have at least 1 selected")
    end
  end

  def self.existing(site)
    if site
      return Webaddress.find(:all, :conditions => ["site = ?", site]).select {|w| !w.categories.empty?}
    else
      return nil
    end
  end

  def self.existing_more(site)
    if site
      return Webaddress.find(:all, :conditions => ["site like ?", '%.'+site]).select {|w| !w.categories.empty?}
    else
      return nil
    end
  end

  def self.existing_less(site)
    if site
      return Webaddress.find(:all, :conditions => ["site = substr(?, -length(site)) and\
               substr(?, -(1+length(site)), 1) = '.'", site, site]).select {|w| !w.categories.empty?}
    else
      return nil
    end
  end

  def check_address(controller)
    self.before_validation
    existing_match = Webaddress.existing(self.site)
    existing_more = Webaddress.existing_more(self.site)
    existing_less = Webaddress.existing_less(self.site)
    existing = false
    if existing_match && (existing_match.length > 0)
      existing = true
      w = existing_match[0]
      link = controller.make_link(w)
      self.errors.add(:site, "already exists: #{link}")
    end
    if existing_more && (existing_more.length > 0)
      existing = true
      list = existing_more.collect {|w| "#{controller.make_link(w)}(#{w.categories.collect {|c| c.name}.join(", ")})"}.join(", ")
      self.errors.add(:site, "exists as more specific: #{list}")
    end
    if existing_less && (existing_less.length > 0)
      existing = true
      list = existing_less.collect {|w| "#{controller.make_link(w)}(#{w.categories.collect {|c| c.name}.join(", ")})"}.join(", ")
      self.errors.add(:site, "exists as more generic: #{list}")
    end
    return existing
  end

  def address
    "#{self.site}#{self.path}"
  end
  
  def lasthistory
    # History.find_by_webaddress_id self.id, :order => "created_at desc"
    self.histories[0] 
  rescue
    nil
  end
  
  def reason= thereason
    @reason = thereason
  end
  
  def reason
    @reason
  end
  
  def update_hosts
    Host.make_dirty
  end
end
