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

      cache = opts[:cache] || (defined?(Cache) && Cache)
      ttl = opts[:ttl] || 300

      define_method("#{attr}_with_caching") do
        if cache && instance_variable_get("@#{attr}").nil?
          identifier = opts[:identifier] ? opts[:identifier].call(self) : self.id
          cache.get("#{self.class.name}::#{attr}::" + identifier.to_s, ttl) do 
            send("#{attr}_without_caching")
          end
        else
          send("#{attr}_without_caching")
        end
      end

      alias_method "#{attr}_without_caching", attr
      alias_method attr, "#{attr}_with_caching"

      unless opts[:memoize] == false
        
        define_method("#{attr}_with_memoization") do 
          value = instance_variable_get("@#{attr}")
          if value.nil?
            value = instance_variable_set("@#{attr}", send("#{attr}_without_memoization"))
          end
          value
        end

        alias_method "#{attr}_without_memoization", attr
        alias_method attr, "#{attr}_with_memoization"
      end

      define_method("invalidate_#{attr}") do 
        if cache
          identifier =  opts[:identifier] ? opts[:identifier].call(self) : self.id
          cache_key = "#{self.class.name}::#{attr}::" + identifier.to_s
          cache.delete(cache_key)
        end
      end
      
      # refreshs the cached attribute
      define_method("refresh_#{attr}") do
        if cache
          identifier = opts[:identifier] ? opts[:identifier].call(self) : self.id
          set_method = cache.respond_to?(:set) ? :set : :put
          val = send("#{attr}_without_caching")
          cache.send(set_method, "#{self.class.name}::#{attr}::#{identifier.to_s}", val, ttl)
        end
      end
      
    end
  end
  
  def self.included(klass)
    klass.extend ClassMethods
  end
end
