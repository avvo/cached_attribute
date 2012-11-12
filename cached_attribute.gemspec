spec = Gem::Specification.new do |s|
  s.name = 'cached_attribute'
  s.version = '0.0.1'
  s.summary = 'Cache values across object instances'
  s.author = "Justin Weiss"
  s.email = "jweiss@avvo.com"
  s.homepage = "http://code.avvo.com/2009/03/introducing-cached_attribute-cached-values-across-object-instances.html"
  s.extra_rdoc_files = ['README.markdown']
  s.has_rdoc = true

  s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.test_files = Dir.glob('test/*_test.rb')

end
