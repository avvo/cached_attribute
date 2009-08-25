require 'digest/sha1'
require 'pp'

module CachedAttribute
  module ClassMethods

    #
    # specifies that the attribute +attr+ should be cached. By default, the cache specified
    # by the instance variable +Cache+ is used. +cached_attribute+ will also memoize the
    # attribute by default.
    #
    # Options:
    #
    #   :ttl         - The ttl (in seconds) for the cached attribute. Defaults to 5 minutes.
    #   :cache       - The cache store object to use for caching. Must respond to #get (with block)
    #                  and #delete and #set or #put (key, value, expiry).
    #   :identifier  - A block that takes a single parameter (of the object containing the cached
    #                  attribute) and returns an identifier unique to that object. Defaults to
    #                  lambda {|s| s.id}, which works fine for activerecord objects.
    #   :memoize     - Whether the return value should be memoized into an instance variable.
    #                  Defaults to true.
    #
    #
    # Example:
    #
    #   class ComplicatedModel < ActiveRecord::Base
    #
    #     def expensive_operation
    #       ... something expensive ...
    #     end
    #
    #     # caches the calls to expensive_operation
    #     cached_attribute :expensive_operation
    #
    #   end
    #
    def cached_attribute(attr, opts = {})

      cache = opts[:cache] || (defined?(CACHE) && CACHE)
      ttl = opts[:ttl] || 300

      define_method("#{attr}_cache_key") do |*prms|
        if prms.present?
          identifier = prms.pretty_inspect # pretty inspect works nicely because it properly escpaes all the params into one string
        else
          identifier = opts[:identifier] ? opts[:identifier].call(self) : self.id
        end
        # need to special case when we're caching class methods
        klass_string = "#{self.class == Class ? self.name + '::self' : self.class.name}"
        "#{klass_string}::#{attr}::#{Digest::SHA1.hexdigest(identifier)}"
      end

      define_method("#{attr}_with_caching") do |*prms|
        if cache && (instance_variable_get("@#{attr}").nil? || prms.present?)
          cache.get(send("#{attr}_cache_key", prms), ttl) do
            send("#{attr}_without_caching", *prms)
          end
        else
          send("#{attr}_without_caching", *prms)
        end
      end

      alias_method "#{attr}_without_caching", attr
      alias_method attr, "#{attr}_with_caching"

      unless opts[:memoize] == false

        define_method("#{attr}_with_memoization") do |*prms|
          value = instance_variable_get("@#{attr}")
          if value.nil? || prms.present? # skip memoization if there are prms
            value = instance_variable_set("@#{attr}", send("#{attr}_without_memoization", *prms))
          end
          value
        end

        alias_method "#{attr}_without_memoization", attr
        alias_method attr, "#{attr}_with_memoization"
      end

      define_method("invalidate_#{attr}") do |*prms|
        if cache
          cache_key = send("#{attr}_cache_key", prms)
          cache.delete(cache_key)
        end
      end

      # refreshs the cached attribute
      define_method("refresh_#{attr}") do |*prms|
        if cache
          set_method = cache.respond_to?(:set) ? :set : :put
          val = send("#{attr}_without_caching")
          cache.send(set_method, send("#{attr}_cache_key", prms), val, ttl)
        end
      end

    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
