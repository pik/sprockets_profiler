require_dependency "sprockets_profiler/application_controller"
require 'sprockets_profiler'

module SprocketsProfiler
  class IndexController < ApplicationController
    def flame_graph(log_file=nil)
      log_file ||= Config.log_entries.last
      @flame_graph_data = Printer.new(log_file).flame_graph_data.to_json
    end
  end
end
