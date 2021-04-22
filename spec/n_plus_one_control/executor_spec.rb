# frozen_string_literal: true

require "spec_helper"

describe NPlusOneControl::Executor do
  let(:populate) do
    ->(n) { create_list(:post, n) }
  end

  let(:observable) do
    -> { Post.find_each(&:user) }
  end

  it "raises when block is missing" do
    expect { described_class.new(population: populate).call }
      .to raise_error(ArgumentError, "Block is required!")
  end

  it "returns correct counts for default scales", :aggregate_failures do
    result = described_class.new(population: populate).call(&observable)

    expect(result.size).to eq 2
    expect(result.first[0]).to eq 2
    expect(result.first[1][:db].size).to eq 3
    expect(result.last[0]).to eq 3
    expect(result.last[1][:db].size).to eq 4
  end

  it "returns correct counts for custom scales", :aggregate_failures do
    result = described_class.new(
      population: populate,
      scale_factors: [5, 10, 100]
    ).call(&observable)

    expect(result.size).to eq 3
    expect(result.first[0]).to eq 5
    expect(result.first[1][:db].size).to eq 6
    expect(result.second[0]).to eq 10
    expect(result.second[1][:db].size).to eq 11
    expect(result.last[0]).to eq 100
    expect(result.last[1][:db].size).to eq 101
  end

  it "returns correct counts with custom match", :aggregate_failures do
    result = described_class.new(
      population: populate,
      matching: /users/
    ).call(&observable)

    expect(result.first[0]).to eq 2
    expect(result.first[1][:db].size).to eq 2
    expect(result.last[0]).to eq 3
    expect(result.last[1][:db].size).to eq 3
  end

  context "with several collectors", :n_plus_one do
    before { NPlusOneControl::CollectorsRegistry.register(another_collector) }
    after { NPlusOneControl::CollectorsRegistry.unregister(another_collector) }

    let(:another_collector) { NPlusOneControl::Collectors::DB.dup.tap { |collector| collector.key = :another_collector } }

    # Here, we test that number of actual proc runs doesn't depend on amount of collectors.
    # There is no better way than test it via our matcher :D
    it "runs block only once" do
      expect { described_class.new.call(collectors: %i[db another_collector].first(current_scale), &observable) }
        .to perform_constant_number_of_queries.with_scale_factors(1, 2)
    end
  end
end
