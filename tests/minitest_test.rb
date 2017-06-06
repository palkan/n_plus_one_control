# frozen_string_literal: true

require_relative "test_helper"

class TestMinitest < Minitest::Test
  def test_no_n_plus_one_error
    populate = ->(n) { create_list(:post, n) }

    assert_perform_constant_number_of_queries(populate: populate) do
      Post.preload(:user).find_each { |p| p.user.name }
    end
  end

  def test_with_n_plus_one_error
    populate = ->(n) { create_list(:post, n) }

    e = assert_raises Minitest::Assertion do
      assert_perform_constant_number_of_queries(populate: populate) do
        Post.find_each { |p| p.user.name }
      end
    end

    assert_match "Expected to make the same number of queries", e.message
    assert_match "3 for N=2", e.message
    assert_match "4 for N=3", e.message
  end

  def test_no_n_plus_one_error_with_scale_factors
    populate = ->(n) { create_list(:post, n) }

    assert_perform_constant_number_of_queries(
      populate: populate,
      scale_factors: [1, 1]
    ) do
      Post.find_each { |p| p.user.name }
    end
  end

  def test_no_n_plus_one_error_with_matching
    populate = ->(n) { create_list(:post, n) }

    assert_perform_constant_number_of_queries(
      populate: populate,
      matching: /posts/
    ) do
      Post.find_each { |p| p.user.name }
    end
  end

  def populate(n)
    create_list(:post, n)
  end

  def test_fallback_to_populate_method
    e = assert_raises Minitest::Assertion do
      assert_perform_constant_number_of_queries do
        Post.find_each { |p| p.user.name }
      end
    end

    assert_match "Expected to make the same number of queries", e.message
  end
end
