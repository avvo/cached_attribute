ActiveRecord::Base.instance_eval do
  include CachedAttribute
end
