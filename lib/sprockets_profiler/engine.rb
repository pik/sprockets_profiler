module SprocketsProfiler
  class Engine < ::Rails::Engine
    isolate_namespace SprocketsProfiler
    config.assets.raise_runtime_errors = false
    config.assets.precompile << 'd3.js' << 'd3-tip.js' << 'd3.flameGraph.js'
  end
end
