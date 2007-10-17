class Deployer
  def self.deploy *hostnames
    hosts = Host.find(:all)
    hosts.each do |host|
      if hostnames.empty? || hostnames.include?(host.hostname)
        puts "Deploying to: #{host.hostname}"
        begin
          res = host.deploy
          puts "Result:"
          puts res
        rescue Exception => e
          puts "Failed to deploy to #{host.hostname}: #{e.message}"
        end
      end
    end
  end
end
