# frozen_string_literal: true

require_relative "test_helper"

class TestMinitestConstantQueries < Minitest::Test
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

  def test_constant_queries_with_custom_collector
    another_collector = NPlusOneControl::Collectors::DB.dup.tap { |collector| collector.key = :secondary_db }
    NPlusOneControl::CollectorsRegistry.register(another_collector)

    populate = ->(n) { create_list(:post, n) }

    assert_perform_constant_number_of_queries(populate: populate, collectors: :secondary_db) do
      Post.preload(:user).find_each { |p| p.user.name }
    end
  ensure
    NPlusOneControl::CollectorsRegistry.unregister(another_collector)
  end

  def test_n_plus_one_queries_with_custom_collector
    another_collector = NPlusOneControl::Collectors::DB.dup.tap do |collector|
      collector.key = :secondary_db
      collector.name = nil
    end

    NPlusOneControl::CollectorsRegistry.register(another_collector)

    populate = ->(n) { create_list(:post, n) }

    e = assert_raises Minitest::Assertion do
      assert_perform_constant_number_of_queries(populate: populate, collectors: :secondary_db) do
        Post.find_each { |p| p.user.name }
      end
    end

    assert_match "SECONDARY_DB", e.message
  ensure
    NPlusOneControl::CollectorsRegistry.unregister(another_collector)
  end
end

class TestMinitestLinearQueries < Minitest::Test
  def test_constant_queries
    populate = ->(n) { create_list(:post, n) }

    assert_perform_linear_number_of_queries(slope: 1, populate: populate) do
      Post.preload(:user).find_each { |p| p.user.name }
    end
  end

  def test_no_n_plus_one_error
    populate = ->(n) { create_list(:post, n) }

    assert_perform_linear_number_of_queries(slope: 1, populate: populate) do
      Post.find_each { |p| p.user.name }
    end
  end

  def test_with_n_plus_one_error
    populate = ->(n) { create_list(:post, n) }

    e = assert_raises Minitest::Assertion do
      assert_perform_linear_number_of_queries(slope: 1, populate: populate) do
        Post.find_each { |p| "#{p.user.name} #{p.category.name}" }
      end
    end

    assert_match "Expected to make linear number of queries", e.message
    assert_match "5 for N=2", e.message
    assert_match "7 for N=3", e.message
  end

  def test_no_n_plus_one_error_with_scale_factors
    populate = ->(n) { create_list(:post, n) }

    assert_perform_linear_number_of_queries(
      populate: populate,
      scale_factors: [2, 3]
    ) do
      Post.find_each { |p| p.user.name }
    end
  end

  def test_no_n_plus_one_error_with_matching
    populate = ->(n) { create_list(:post, n) }

    assert_perform_linear_number_of_queries(
      populate: populate,
      matching: /users/
    ) do
      Post.find_each { |p| p.user.name }
    end
  end

  def test_linear_queries_with_custom_collector
    another_collector = NPlusOneControl::Collectors::DB.dup.tap { |collector| collector.key = :secondary_db }
    NPlusOneControl::CollectorsRegistry.register(another_collector)

    populate = ->(n) { create_list(:post, n) }

    assert_perform_linear_number_of_queries(slope: 1, populate: populate, collectors: :secondary_db) do
      Post.find_each { |p| p.user.name }
    end
  ensure
    NPlusOneControl::CollectorsRegistry.unregister(another_collector)
  end

  def test_n_plus_one_queries_with_custom_collector
    another_collector = NPlusOneControl::Collectors::DB.dup.tap do |collector|
      collector.key = :secondary_db
      collector.name = nil
    end

    NPlusOneControl::CollectorsRegistry.register(another_collector)

    populate = ->(n) { create_list(:post, n) }

    e = assert_raises Minitest::Assertion do
      assert_perform_linear_number_of_queries(slope: 1, populate: populate, collectors: :secondary_db) do
        Post.find_each { |p| "#{p.user.name} #{p.category.name}" }
      end
    end

    assert_match "SECONDARY_DB", e.message
  ensure
    NPlusOneControl::CollectorsRegistry.unregister(another_collector)
  end
end

class TestMinitestPopulateMethod < Minitest::Test
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

  def test_current_scale_avalability
    mock = Minitest::Mock.new
    NPlusOneControl.default_scale_factors.each do |scale_factor|
      mock.expect :limit, nil, [scale_factor]
    end

    assert_perform_constant_number_of_queries { mock.limit(current_scale) }
  end
end
