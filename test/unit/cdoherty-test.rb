
require "minitest/autorun"
require "pp"
require "rr"
require "scope"

require "./cdoherty"

class CdohertyTest < Scope::TestCase
  context "graph implementation" do
    setup do
      @graph = Cdoherty::Graph.new
    end

    should "add edges to the graph" do
      @graph.add(:narf, :poit)
      @graph.add(:hrungnir, :sputnik)
      edges = @graph.edges
      assert_equal([:poit], edges[:narf],)
      assert_equal([:sputnik], edges[:hrungnir])
    end

    should "add multiple vertices to an edge" do
      @graph.add(:narf, :poit)
      @graph.add(:narf, :shpongle)
      edges = @graph.edges
      assert_equal([:poit, :shpongle], edges[:narf])
    end

    should "return an edge's neighbors" do
      @graph.add(:narf, :poit)
      @graph.add(:narf, :shpongle)
      assert_equal([:poit, :shpongle], @graph.neighbors(:narf))
    end

    should "add multiple neighbors at once" do
      @graph.add(:narf, [:poit, :shpongle, :sputnik])
      assert_equal([:poit, :shpongle, :sputnik], @graph.neighbors(:narf))
    end

    should "not duplicate edges for a new vertex" do
      @graph.add(:narf, [:poit, :poit])
      assert_equal([:poit], @graph.neighbors(:narf))
    end

    should "not duplicate edges for an existing vertex" do
      @graph.add(:narf, [:poit])
      @graph.add(:narf, [:poit])
      assert_equal([:poit], @graph.neighbors(:narf))
    end
  end

  context "helper functions" do
    setup do
      @finder = Cdoherty::GraphBuilder.new
      @finder.words = %w{smart start stark stack slack black blank bland brand braid brain smack }
    end

    should "return correct list of transition regexes" do
      expected = ".ink|o.nk|oi.k|oin."
      actual = @finder.create_regex("oink")
      assert_equal(expected, actual)
    end

    should "return correct, unfiltered list of next steps" do
      start = "stack"
      expected = %w{slack smack stark}

      actual = @finder.find_transitions(start)
      assert_equal(expected, actual)
    end

    should "generate correct adjacency list from word list" do
      expected = {
        "smart" => ["start"],
        "start" => ["smart", "stark"],
        "stark" => ["stack", "start"],
        "stack" => ["slack", "smack", "stark"],
        "slack" => ["black", "smack", "stack"],
        "black" => ["blank", "slack"],
        "blank" => ["black", "bland"],
        "bland" => ["blank", "brand"],
        "brand" => ["bland", "braid"],
        "braid" => ["brain", "brand"],
        "brain" => ["braid"],
        "smack" => ["slack", "stack"]
      }
      graph = @finder.generate_graph
      assert_equal(expected, graph.edges)
    end

    should "print data about the full graph" do
      builder = Cdoherty::GraphBuilder.new
      graph = builder.generate_graph
      puts "Vertices: #{graph.edges.size}"
      puts "Edges: #{graph.edges.values.inject(0) { |sum, a| sum += s.size }}"
    end
  end
end
