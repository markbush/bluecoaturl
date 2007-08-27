require 'digest/sha1'

class User < ActiveRecord::Base

  has_many                  :webaddresses

  validates_presence_of     :name
  validates_uniqueness_of   :name

  attr_accessor             :password_confirmation, :old_password
  validates_confirmation_of :password
  attr_protected            :admin

  def validate
    errors.add_to_base("Missing password") if hashed_password.blank?
  end
  def before_save
    self.can_deploy = true if self.admin?
  end

  def self.authenticate(name, password)
    user = self.find_by_name(name)
    if user and ! user.authenticate(password)
      user = nil
    end
    user
  end

  def authenticate(password)
    result = true
    expected_password = User.encrypted_password(password, self.salt)
    if ! self.enabled or self.hashed_password != expected_password
      result = false
    end
    result
  end

  def password
    @password
  end

  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    create_new_salt
    self.hashed_password = User.encrypted_password(self.password, self.salt)
  end

  def after_destroy
    if User.count.zero?
      raise "Can't delete last user"
    end
  end

  private

  def self.encrypted_password(password, salt)
    string_to_hash = password + "bluecoat-stuff" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end

  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end
end
