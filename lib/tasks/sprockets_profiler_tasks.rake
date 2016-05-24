require 'sprockets_profiler'
require "pry"; require "pry-byebug";

namespace :assets do
  namespace :profiler do
    task :full_dump, [:log_file] do |t, args|
      SprocketsProfiler::Printer.new(args[:log_file]).full_report
    end
    task :full_stat, [:log_file] do |t, args|
      SprocketsProfiler::Printer.new(args[:log_file]).full_stat
    end
    task :show_slowest, [:log_file, :limit] do |t, args|
      SprocketsProfiler::Printer.new(args[:log_file]).show_slowest(args[:limit] || 3)
    end
  end
end
