SprocketsProfiler::Engine.routes.draw do
  get '/:log_file', action: :flame_graph, controller: :index
  get '/', action: :flame_graph, controller: :index
end
