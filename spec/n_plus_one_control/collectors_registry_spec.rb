# frozen_string_literal: true

require "spec_helper"

describe NPlusOneControl::CollectorsRegistry do
  describe ".register" do
    subject(:register) { described_class.register(test_collector) }

    after { described_class.unregister(test_collector) }

    let(:test_collector) { Struct.new(:key).new(:__test_register) }

    specify do
      register
      expect(described_class.get(:__test_register)).to eq(test_collector)
    end
  end

  describe ".slice" do
    subject(:sliced_collectors) { described_class.slice(*collector_keys) }

    let(:collector_keys) { [:db] }

    specify { expect(sliced_collectors).to eq(db: ::NPlusOneControl::Collectors::DB) }

    context "when undefined key passed" do
      let(:collector_keys) { [:__test_slice_undefined_key] }

      specify { expect { sliced_collectors }.to raise_error(ArgumentError, /: __test_slice_undefined_key, exsiting collectors are: db/) }
    end
  end
end
