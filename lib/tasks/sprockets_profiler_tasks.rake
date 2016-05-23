namespace :assets do
  namespace :profiler do
    task :full_report, [:log_file] do |log_file=nil|
      Printer.new(log_file).full_report
    end
    task :full_stat, [:log_file] do |log_file=nil|
      Printer.new(log_file).full_stat
    end
    task :show_slowest, [:log_file, :limit] do |log_file=nil, limit=3|
      SprocketsProfiler::Printer.new(log_file).show_slowest(limit)
    end
  end
end
