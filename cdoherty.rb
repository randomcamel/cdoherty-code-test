#!/usr/bin/env ruby

require "yaml"
require "logger"
require "parallel"

DICT_FILE = ENV["DICT"] || "short-dict.txt"
DEFAULT_NUM_PROCS = 7

module Cdoherty

  # a vertex is any object, but happens to be strings for us.
  class Graph

    def initialize
      @log = Logger.new STDOUT
      @log.level = Logger::INFO

      @cache_file = "#{DICT_FILE}.yaml"

      if File.exists?(@cache_file)
        @log.info "Loading YAML from #{@cache_file}"
        @adj_list = load_from_file
      else
        @adj_list = {}
      end

    end

    def add(v1, v2)
      return if v1 == v2

      raise StandardError.new "v1 is an array #{v1.inspect}" if v1.class == Array
      raise StandardError.new "v2 is an array #{v2.inspect}" if v2.class == Array

      @adj_list[v1] ||= []
      @adj_list[v2] ||= []

      @adj_list[v1] |= [v2]    # pipe (|) on arrays performs a set union, to eliminate duplicates.
      @adj_list[v2] |= [v1]
      [v1, v2].each { |v| @adj_list[v].sort! }
      @log.debug "Added node (#{v1}, #{v1})"
    end

    def neighbors(v1)
      @adj_list[v1] || []
    end

    def edges
      @adj_list
    end

    def find_path(start, target, opts={})
      return_all_parents = !!opts[:return_all_parents]   # !! is an idiom to convert values to boolean.

      discovered = Hash.new(false)
      processed = Hash.new(false)

      parents = {}
      q = []
      v_current = start
      q.push(v_current)
      discovered[v_current] = true
      parents = {}

      while q.size > 0
        v_current = q.shift
        @log.debug  "about to visit '#{v_current}'"
        processed[v_current] = true
        self.neighbors(v_current).each do |neighbor|

          @log.debug "processing node #{neighbor}" unless !processed[neighbor]

          if !discovered[neighbor]
            q.push(neighbor)
            discovered[neighbor] = true
            parents[neighbor] = v_current

            break if v_current == target && !return_all_parents
          end
        end
        @log.debug  "done processing node '#{v_current}'"
      end

      if return_all_parents
        return parents
      else
        return show_path(parents, start, target)
      end
    end

    def show_path(parents, start, target)
      path = [target]
      while parents[target] != start
        path.push(parents[target])
        target = parents[target]                  
      end
      path.push(start)
      return path.reverse
    end

    def write_to_file
      File.open(@cache_file, "w") do |out|
        YAML.dump(@adj_list, out)
      end
    end

    def load_from_file
      struct = nil
      File.open(@cache_file) do |data|
        struct = YAML.load(data)
      end
      return struct
    end
  end

  class GraphBuilder

    attr_accessor :words

    def initialize(wordlist=nil)
      if wordlist
        @words = wordlist
      else
        @words = load_dict
      end
    end

    # generate the full dict at any time with `egrep -e '^[a-z]{5}$' /usr/share/dict/words`.
    def load_dict
      raw = File.read(DICT_FILE)
      words = raw.split("\n").map { |word| word.strip }.reject { |word| word.nil? || word.length == 0 }
      return words
    end

    def valid_transition?(s1, s2)
      diffs = 0
      s1.length.times do |i|
        if s1[i] != s2[i]
          diffs += 1
          return false if diffs > 1
        end
      end
      return diffs == 1
    end

    def find_transitions(word)
      transitions = []
      @words.each do |dict_word|
        if valid_transition?(word, dict_word)
          transitions << dict_word
        end
      end
      return transitions.reject { |w| w == word }.sort
    end

    def generate_graph(parallel=false)
      graph = Graph.new

      nprocs = parallel ? DEFAULT_NUM_PROCS : 0

      # the parallel gem maintains the order of the results...
      words_transitions =
        Parallel.map(@words, :in_processes => nprocs) do |word|
        find_transitions(word)
      end
      # ...so we can just iterate over the input array and it's the same index.
      @words.each_with_index do |word, i|
        words_transitions[i].each do |transition|
          graph.add(word, transition)
        end
      end
      return graph
    end
  end
end

start = "smart"
FINAL = "brain"
