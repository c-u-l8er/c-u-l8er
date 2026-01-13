defmodule CUL8erTest do
  use ExUnit.Case
  doctest CUL8er

  test "DSL compiles and creates topology data structure" do
    defmodule TestTopology do
      use CUL8er

      topology :test do
        host :local do
          address "localhost"
          platform :arch_linux
        end

        resource :web, type: :container, on: :local do
          from_image "images:alpine/3.19"
        end
        
        strategy do
          approach :rolling
        end
      end
    end

    topology = TestTopology.test()
    
    assert topology.name == :test
    assert Map.has_key?(topology.hosts, :local)
    assert Map.has_key?(topology.resources, :web)
    assert topology.strategy.approach == :rolling
  end
end
