require_dependency "sprockets_profiler/application_controller"
require 'sprockets_profiler'

module SprocketsProfiler
  class IndexController < ApplicationController
    def flame_graph(log_file=nil)
      log_file ||= Config.latest_log
      @flame_graph_data = Printer.new(log_file).flame_graph_data.to_json
      render file: "#{Rails.root.join('/lib/sprockets_profiler/index.html.erb')}"
    end
  end
end
