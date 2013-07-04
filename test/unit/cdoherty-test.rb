
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

    should "add multiple edges to a vertex" do
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

    should "refuse to add multiple neighbors at once" do
      assert_raises(StandardError) { @graph.add(:narf, [:poit, :shpongle, :sputnik]) }
    end

    should "not duplicate edges for a vertex" do
      @graph.add(:narf, :poit)
      @graph.add(:narf, :poit)
      assert_equal([:poit], @graph.neighbors(:narf))
    end

    should "make bidirectional edges" do
      @graph.add(:narf, :poit)
      assert_equal([:poit], @graph.neighbors(:narf))
      assert_equal([:narf], @graph.neighbors(:poit))
    end
  end

  context "graph and word integration functions" do
    setup do
      @words = %w{smart start stark stack slack black blank bland brand braid brain smack fakes fakez}
      @builder = Cdoherty::GraphBuilder.new(@words)
    end

    should "accurately determine word presence" do
      assert(@builder.contains?("start"), "Builder erroneously claims not to know 'start'.")
      refute(@builder.contains?("gragh"), "Builder erroneously claims to know 'gragh'.")
    end

    should "determine valid transitions" do
      refute(@builder.valid_transition?("string1", "string1"), "Same string")
      assert(@builder.valid_transition?("string1", "string2"), "Should be valid")
      refute(@builder.valid_transition?("string1", "strinh2"), "Hamming distance 2, should fail")
      refute(@builder.valid_transition?("stark", "smart"), "distance 2, should fail")
      assert(@builder.valid_transition?("smack", "slack"))
      assert(@builder.valid_transition?("slack", "smack"))
    end

    should "return correct, unfiltered list of next steps" do
      start = "stack"
      expected = %w{slack smack stark}

      actual = @builder.find_transitions(start)
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
        "smack" => ["slack", "stack"],
        "fakes"=>["fakez"],
        "fakez"=>["fakes"],
      }
      graph = @builder.generate_graph
      assert_equal(expected, graph.edges)
    end
  end

  context "graph search" do
    setup_once do
      @@test_words = %w{smart start stark stack slack black blank bland brand braid brain fakes fakez}
      @@shortest_path = @test_words

      @@builder = Cdoherty::GraphBuilder.new(@@test_words)
      @@graph = @@builder.generate_graph

      @@simple_parents = {
        "start"=>"smart",
        "stark"=>"start",
        "stack"=>"stark",
        "slack"=>"stack",
        "black"=>"slack",
        "blank"=>"black",
        "bland"=>"blank",
        "brand"=>"bland",
        "braid"=>"brand",
        "brain"=>"braid"
      }
    end

    should "correctly construct a path from a parents hash" do
      expected_path = ["smart", "start", "stark", "stack", "slack", "black",
                       "blank", "bland", "brand", "braid", "brain"]

      actual_path = @@graph.show_path(@@simple_parents, "smart", "brain")
      assert_equal(expected_path, actual_path)
    end

    should "find the correct path and parent list through a simple graph" do
      expected_parents = @@simple_parents
      expected_path = ["smart", "start", "stark", "stack", "slack", "black", "blank", "bland", "brand", "braid", "brain"]

      start, target = "smart", "brain"
      actual_parents = @@graph.find_path(start, target, :return_all_parents => true)
      assert_equal(expected_parents, actual_parents)

      actual_path = @@graph.find_path(start, target)
      assert_equal(expected_path, actual_path)
    end

    should "fail to find a path where none exists" do
      start, target = "smart", "fakez"
      actual_path = @@graph.find_path(start, target)
      assert_equal([], actual_path)
    end

    should "refuse to operate on unknown words" do
      real = "craze"
      fake = "gragh"
      [ [real, fake], [fake, real] ].each do |arg_pair|
        assert_raises(StandardError) { @@graph.find_path(*arg_pair) }
      end
    end
  end
end
