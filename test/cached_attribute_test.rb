require 'test/unit'
require File.join(File.dirname(__FILE__), '../lib/cached_attribute')
require 'init'
require 'rubygems'
require 'activesupport'

class DummyCache

  def self.reset
    @data = {}
    @cache_hit = false
    @last_get = nil
    @last_set = nil
  end
  reset

  def self.cache_hit?
    @cache_hit
  end
  
  def self.last_set
    @last_set
  end

  def self.last_get
    @last_get
  end
  
  def self.get(key, ttl = 60, &block)
    
    value, expires = @data[key]

    if !value || expires < Time.now
      if block
        value, expires = set(key, block.call, ttl)
      else
        value, expires = Time.now
      end
    else
      @cache_hit = true
      @last_get = value
    end
    value
  end

  def self.delete(key)
    @data[key] = nil
  end

  def self.set(key, value, ttl = 60)
    @last_set = Time.now
    @data[key] = [value, Time.now + ttl]
  end

end

class BaseModel

  class << self
    def expensive_class_method(number)
      number + 50
    end
    cached_attribute :expensive_class_method, :cache => DummyCache
  end

  def expensive_instance_method(p1, p2)
    p1 + p2
  end
  cached_attribute :expensive_instance_method, :cache => DummyCache

  def expensive_call
    "hello" * 50
  end

  cached_attribute :expensive_call, :cache => DummyCache, :identifier => lambda {|s| 1}

  def no_memoization
    "hello" * 50
  end

  cached_attribute :no_memoization, :cache => DummyCache, :identifier => lambda {|s| 2}, :memoize => false

  def low_ttl
    "hello" * 50
  end

  cached_attribute :low_ttl, :cache => DummyCache, :identifier => lambda {|s| 3}, :memoize => false, :ttl => 1
end

class CachedAttributeTest < Test::Unit::TestCase
  
  def setup
    DummyCache.reset
    @m = BaseModel.new
  end

  def test_cached_attribute_method_put_on_class
    assert BaseModel.respond_to?(:cached_attribute), "Cached attribute method was not found."
  end

  def test_cached_attribute_enabled
    v = @m.no_memoization
    assert !DummyCache.cache_hit?, "Cache should not be hit on initial call"
    @m.no_memoization
    assert DummyCache.cache_hit?, "Cache should be hit on the second call"
    assert_equal(v, DummyCache.last_get)
  end

  def test_cached_attribute_memoizes_attribute
    v1 = @m.expensive_call
    assert_equal(v1, @m.instance_variable_get("@expensive_call"))
    v2 = @m.expensive_call
    assert_equal(v1, v2)
  end

  def test_cached_attribute_can_be_invalidated
    @m.no_memoization
    assert !DummyCache.cache_hit?, "Cache should not be hit on initial call"
    @m.invalidate_no_memoization
    @m.no_memoization
    assert !DummyCache.cache_hit?, "Cache should not be hit after invalidation"
  end

  def test_ttl_should_work
    @m.low_ttl
    assert !DummyCache.cache_hit?, "Cache should not be hit on initial call"
    sleep 1
    @m.low_ttl
    assert !DummyCache.cache_hit?, "Cache should not be hit after 1 second"
  end

  def test_refresh
    @m.no_memoization
    assert !DummyCache.cache_hit?, "Cache should not be hit on initial call"
    last_set = DummyCache.last_set
    @m.no_memoization
    assert DummyCache.cache_hit?, "Cache should be a hit"
    sleep 1
    @m.refresh_no_memoization
    next_set = DummyCache.last_set
    @m.no_memoization
    assert DummyCache.cache_hit?, "Cache should still be a hit"
    assert(last_set < next_set)
  end

  def test_on_class_method_with_params
    assert_equal(51, BaseModel.expensive_class_method(1))
    assert !DummyCache.cache_hit?, 'First call should be miss'

    assert_equal(51, BaseModel.expensive_class_method(1))
    assert DummyCache.cache_hit?, 'Second call should be hit'
  end

  def test_on_instance_method_with_params
    assert_equal(11, @m.expensive_instance_method(5, 6))
    assert !DummyCache.cache_hit?, 'First call should be miss'

    assert_equal(11, @m.expensive_instance_method(5, 6))
    assert DummyCache.cache_hit?, 'Second call should be hit'
  end

  def test_class_method_key
    assert_equal("BaseModel::self::expensive_class_method::#{Digest::SHA1.hexdigest([1].pretty_inspect)}", BaseModel.expensive_class_method_cache_key(1))
  end

  def test_instance_method_key
    assert_equal("BaseModel::expensive_instance_method::#{Digest::SHA1.hexdigest([1].pretty_inspect)}", @m.expensive_instance_method_cache_key(1))
  end

end
