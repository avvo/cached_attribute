CachedAttribute
===============

CachedAttribute is a plugin that allows expensive model attributes to be cached on a
per-instance basis. It supports memoization, multiple cache stores, invalidation, and ttl.

Example
=======    
    class ComplicatedModel < ActiveRecord::Base
      
      def expensive_operation
        ... something expensive ...
      end
      
      # caches the calls to expensive_operation
      cached_attribute :expensive_operation
    
    end

    c = ComplicatedModel.new
    c.expensive_operation # => slow
    c.expensive_operation # => fast!

    c.invalidate_expensive_operation
    c.expensive_operation # => slow


Copyright (c) 2009 Avvo, Inc., released under the MIT license
