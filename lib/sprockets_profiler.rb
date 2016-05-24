require "sprockets_profiler/engine"

module SprocketsProfiler
  def record
    require 'sprockets'
    yield config if block_given?
    Sprockets::CachedEnvironment.class_eval do
      prepend SprocketsProfiler::CachedEnvironmentProfiler
    end
  end
  module_function :record

  class Config
    class << self
      attr_writer :log_template, :log_dir
      def log_template
        @log_template ||= "sprocket-profiler-%d-%m-%y.log"
      end

      def log_dir
        log_dir ||= Rails.root.join('log/sprockets_profiler')
      end

      def log_file_path
        Rails.root.join(log_dir).join(Time.now.strftime(log_template))
      end

      def log_entries
        Dir[SprocketsProfiler::Config.log_dir.join('*.log')]
      rescue
        []
      end
    end
  end

  class Printer
    NEST_SYMBOL = "\u{2514}\u{2500}\u{2500}\u{2500}"
    NEST_SPACE = "    "
    attr_reader :log_file

    def initialize(log_file=nil)
      @log_file = log_file || SprocketsProfiler::Config.log_file_path
    end

    def strip_uri(uri)
      uri.gsub(/.*:/, '').gsub(/\?.*/, '')
    end

    def sort_nodes(group, limit)
      # Sort descending order
      group.sort_by {|k, v| -v['time'] }[0...limit]
    end

    def traverse_prepare_flame_graph(dict)
      dict.each_with_object([]) do |(k,v), group|
        group << { name: k, children: traverse_prepare_flame_graph(v['depends']), value: v['time'] }
      end
    end

    def flame_graph_data
      flame_graph_data = profiles.map do |profile|
        traverse_prepare_flame_graph(profile)
      end
      flame_graph_data = flame_graph_data.map(&:first)
      { name: 'root', value: flame_graph_data.sum {|node| node[:value]}, children: flame_graph_data }
    end

    def traverse_sort_print_profiles(profiles, limit=3)
      profile_group = profiles.each_with_object([]) do |profile, group|
        group.concat(profile.to_a)
      end
      traverse_sort_print(sort_nodes(profile_group, limit), limit: limit)
    end


    def traverse_sort_print(dict, depth=0, limit:)
      traverse_print(dict, depth) do |v, depth|
        traverse_sort_print(sort_nodes(v['depends'], limit), depth + 1, limit: limit)
      end
    end

    def traverse_print(dict, depth=0)
      dict.each do |k,v|
        # Ruby is pecuiliar about who is on the right unlike python
        a = NEST_SPACE * (depth > 0 ? depth - 1 : 0)
        a += NEST_SYMBOL if depth > 0
        puts "#{a}#{v['time']} #{strip_uri(k)}"
        if v['depends'].present?
          if block_given?
            yield [v, depth]
          else
            traverse_print(v['depends'], depth + 1)
          end
        end
      end
    end

    def profiles
      @profiles ||= begin
        raw = File.open(log_file, 'r') { |file| file.readlines }
        raw.map { |raw_profile| JSON.parse(raw_profile) }
      rescue Errno::ENOENT => e
        puts "Could not open log_file for reading.\n#{e.message}"
        raise e
      end
    end

    def show_slowest
      traverse_sort_print_profiles(profiles)
    end

    def full_report
      profiles.each do |profile|
        traverse_print(profile)
      end
    end

    def traverse_stat_merge(collection, sample)
      sample.each do |k,v|
        if collection[k]
          samples = collection[k]['samples']
          collection[k]['time'] = (collection[k]['time'] * samples + v['time']) / (samples + 1)
          collection[k]['samples'] += 1
        else
          collection[k] = { 'time' => v['time'], 'samples' => 1, 'depends' => {}}
        end
        if v['depends'].present?
          traverse_stat_merge(collection[k]['depends'], v['depends'])
        end
      end
    end

    def full_stat
      stats = profiles.each_with_object({}) do |profile, h|
        traverse_stat_merge(h, profile)
      end
      traverse_print(stats)
    end

    def show_dups
    end
  end

  module CachedEnvironmentProfiler
    def profiler
      @profiler ||= {}
    end

    def current_path
      @current_path ||= []
    end

    def node_for_path(path=nil)
      if path.present?
        path.inject(profiler) { |profiler, key| profiler[key][:depends] }
      else
        profiler
      end
    end

    def log_profile
      `mkdir -p #{SprocketsProfiler::Config.log_dir}`
      File.open(SprocketsProfiler::Config.log_file_path, 'a+') do |file|
        file.write(profiler.to_json + "\n")
      end
    end

    def profile_asset(key)
      start = Time.now
      node_for_path(current_path)[key] = { depends: {}, time: nil }
      current_path << key
      ret = yield
      node_for_path(current_path[0...-1])[key][:time] = Time.now - start
      current_path.pop
      # Log the profile if we're done with the current hierachy
      if current_path.empty?
        log_profile
      end
      ret
    end

    def load_from_unloaded(unloaded)
      profile_asset(unloaded.asset_key) do
        super(unloaded)
      end
    end

    def asset_from_cache(asset_key)
      profile_asset(asset_key) do
        super(asset_key)
      end
    end
  end
end
