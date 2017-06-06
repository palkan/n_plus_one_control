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
    expect { described_class.call(population: populate) }
      .to raise_error(ArgumentError, "Block is required!")
  end

  it "raises when populate is missing" do
    expect { described_class.call(&observable) }
      .to raise_error(ArgumentError, /population/)
  end

  it "returns correct counts for default scales" do
    result = described_class.call(
      population: populate,
      &observable
    )

    expect(result.size).to eq 2
    expect(result.first[0]).to eq 2
    expect(result.first[1].size).to eq 3
    expect(result.last[0]).to eq 3
    expect(result.last[1].size).to eq 4
  end

  it "returns correct counts for custom scales" do
    result = described_class.call(
      population: populate,
      scale_factors: [5, 10, 100],
      &observable
    )

    expect(result.size).to eq 3
    expect(result.first[0]).to eq 5
    expect(result.first[1].size).to eq 6
    expect(result.second[0]).to eq 10
    expect(result.second[1].size).to eq 11
    expect(result.last[0]).to eq 100
    expect(result.last[1].size).to eq 101
  end

  it "returns correct counts with custom match" do
    result = described_class.call(
      population: populate,
      matching: /users/,
      &observable
    )

    expect(result.first[0]).to eq 2
    expect(result.first[1].size).to eq 2
    expect(result.last[0]).to eq 3
    expect(result.last[1].size).to eq 3
  end
end
