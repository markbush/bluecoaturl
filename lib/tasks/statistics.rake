STATS_DIRECTORIES = [
  %w(Controllers        app/controllers),
  %w(Helpers            app/helpers), 
  %w(Models             app/models),
  %w(Views              app/views),
  %w(APIs               app/apis),
  %w(Components         components),
  %w(Unit\ tests        test/unit),
  %w(Functional\ tests  test/functional),
  %w(Integration\ tests test/integration)

].collect { |name, dir| [ name, "#{RAILS_ROOT}/#{dir}" ] }.select { |name, dir| File.directory?(dir) }

desc "Report code statistics (KLOCs, etc) from the application (including views)"
task :fullstats do
  require 'code_statistics_with_views'
  CodeStatisticsWithViews.new(*STATS_DIRECTORIES).to_s
end
