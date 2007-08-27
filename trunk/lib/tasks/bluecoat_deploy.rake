RSOURCE = ENV['HOME']+'/Src/Rails'
PROD = '/usr/local/Rails'
STYLESHEETS = '/Library/WebServer/Documents/stylesheets'

desc "Deploy application to Locomotive on minime"
task :minime do
  puts "Deploying files from #{RSOURCE}/bluecoat to minime:#{RSOURCE}"
  system("cd #{RSOURCE} ; rsync -av --exclude=bluecoat/log --delete bluecoat minime:#{RSOURCE}")
end

desc "Deploy application to Production on minime"
task :deploy do
  puts "Deploying files from #{RSOURCE}/bluecoat to minime:#{PROD}"
  system("cd #{RSOURCE} ; rsync -av --exclude=bluecoat/log --delete bluecoat minime:#{PROD}")
  system("ssh minime 'cd #{PROD}/bluecoat; RAILS_ENV=production rake db:migrate; mongrel_rails cluster::restart'")
end

desc "Load application stylesheet to main web server"
task :stylesheet do
  puts "Deploying stylesheet from #{RSOURCE}/bluecoat/public/stylesheets to hal:#{STYLESHEETS}"
  system("cd #{RSOURCE} ; rsync -av --delete bluecoat/public/stylesheets/bluecoat.css hal:#{STYLESHEETS}")
end
