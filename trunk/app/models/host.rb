require 'expecter'

class Host < ActiveRecord::Base

  validates_presence_of      :hostname
  validates_uniqueness_of    :hostname
  validates_presence_of      :username
  validates_presence_of      :password
  validates_presence_of      :enable_password

  attr_accessor              :password_confirmation, :enable_password_confirmation
  validates_confirmation_of  :password, :enable_password

  # Ensure that a host is marked as not updated when created
  def before_create
    self.dirty = true
  end
  # Simple mechanism to prevent passwords appearing in
  # the database in the clear.
  # This is NOT secure!
  # These methods can be replaced to use a reversible
  # cryptographic procedure, but the key would have
  # to be stored in a location known to and
  # accessible from the application when running.
  def before_save
    self.password = [self.password].pack('m')
    self.enable_password = [self.enable_password].pack('m')
  end
  def after_save
    self.password = self.password.unpack('m')[0]
    self.enable_password = self.enable_password.unpack('m')[0]
  end
  alias_method :after_find, :after_save

  def deploy
    e = Expect::Expecter.new
    e.ssh_connect(self.hostname, self.username, self.password)
    d = e.expect([['>', "enable\n", true],
                  ['Invalid password', :CLOSE],
                  ['Enable Password:', "#{enable_password}\n", true],
                  ['#$', "conf t\n", true],
                  ['#\(config\)', "content-filter\n", true],
                  ['#\(config content-filter\)', "local\n", true],
                  ['#\(config local\)', "download get-now\n"]])
    d = e.expect([['failed', "exit\n"], ['ok', "exit\n"]])
    self.update_attribute(:dirty, false) if d[1] == 'ok'
    d = e.expect([['#', "exit\n", true]])
    e.close if e.open?
  end

  def self.make_dirty
    logger.debug("Host make_dirty")
    Host.find(:all, :conditions => ["dirty = ?", false]).each do |host|
      logger.debug("Host #{host.hostname} setting dirty")
      host.update_attribute(:dirty, true)
    end
  end
end
