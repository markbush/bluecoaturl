require 'rubygems'
require 'RMagick'

class Category < ActiveRecord::Base
  include Magick

  has_and_belongs_to_many :webaddresses, :order => :site

  validates_presence_of   :name
  validates_presence_of   :description
  validates_uniqueness_of :name
  validates_length_of     :name,        :maximum => 64
  validates_format_of     :name,        :with => /^[A-Za-z0-9_]*$/,
                                        :message => "may only contain A-Z, a-z, 0-9 and _ (no white space)"

  before_save             :set_image
  after_save              :update_hosts
  after_destroy           :update_hosts

  def set_image
    mImage = Magick::Image.new(8 * self.name.length, 25) { self.background_color = 'white'}
    drawer = Magick::Draw.new

    drawer.annotate(mImage, 0, 0, 0, 0, self.name) do
      self.gravity = Magick::WestGravity
      self.pointsize = 14
      self.font_family = 'Helvetica'
    end

    mImage.rotate! -90
    self.image = mImage.to_blob { self.format = 'GIF' }
  end
  
  def update_hosts
    Host.make_dirty
  end
end
