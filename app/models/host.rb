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
    if d.nil? || d[2].nil?
      # Didn't match anything
      return "Unexpected response: #{d.inspect}"
    elsif d[2].eql?(:TIMEOUT)
      return "Timeout while communicating with remote end"
    end
    d = e.expect([['failed', "exit\n"], ['ok', "exit\n"]])
    if d.nil? || d[2].nil?
      # Didn't match anything
      return "Unexpected response: #{d.inspect}"
    elsif d[2].eql?(:TIMEOUT)
      return "Timeout while communicating with remote end"
    end
    result = d[0]
    self.update_attribute(:dirty, false) if d[1] == 'ok'
    d = e.expect([['#', "exit\n", true]])
    e.close if e.open?
    result
  end

  def self.make_dirty
    logger.debug("Host make_dirty")
    Host.find(:all, :conditions => ["dirty = ?", false]).each do |host|
      logger.debug("Host #{host.hostname} setting dirty")
      host.update_attribute(:dirty, true)
    end
  end

  def testurl *urllist
    e = Expect::Expecter.new
    e.ssh_connect(self.hostname , self.username, self.password)
    d = e.expect([['>' , "enable\n" , true],
                  ['Invalid password', :CLOSE],
                  ['Enable Password:', "#{enable_password}\n", true],
                  ['#$', "conf t\n", true],
                  ['#\(config\)', "content-filter\n", true],
                  ['#\(config content-filter\)', nil]])
    results={}
    urllist.each do |url|
      # test each URL
      e.send "test-url #{url}\n"
      d = e.expect([['#\(config content-filter\)', nil]])
      lines=d[0].split /[\n\r]+/
      lines.pop
      lines.shift
      lines.shift
      results[url]=lines.join "\n"
    end 
    e.send "exit\n"
    d = e.expect([['#', "exit\n", true]])
    e.close if e.open?
    results
  end 
                  
end
