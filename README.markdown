CachedAttribute
===============

CachedAttribute is a plugin that allows expensive model attributes to be cached on a
per-instance basis. It supports memoization, multiple cache stores, invalidation, and ttl.

It can also be used to cached arbitrary methods based on their

Example
=======    
    class ComplicatedModel < ActiveRecord::Base
      
      def expensive_operation
        ... something expensive ...
      end
      
      # caches the calls to expensive_operation
      cached_attribute :expensive_operation

      class << self
        def expensive_class_method(param1)
          ... something expensive ...
        end
        cached_attribute :expensive_class_method
      end

    end

    c = ComplicatedModel.new
    c.expensive_operation # => slow
    c.expensive_operation # => fast!

    c.invalidate_expensive_operation
    c.expensive_operation # => slow

    ComplicatedModel.expensive_class_method('some string or something') # => slow
    ComplicatedModel.expensive_class_method('some other string or something') # => slow
    ComplicatedModel.expensive_class_method('some string or something') # => fast



Copyright (c) 2009 Avvo, Inc., released under the MIT license
