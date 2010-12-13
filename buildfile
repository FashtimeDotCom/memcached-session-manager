# Generated by Buildr 1.3.3, change to your liking
# Standard maven2 repository
require 'etc/checkstyle'

repositories.remote << 'http://repo2.maven.org/maven2'
repositories.remote << 'http://www.ibiblio.org/maven2'
repositories.remote << 'http://thimbleware.com/maven'
repositories.remote << 'http://repository.jboss.com/maven2'
#repositories.remote << 'http://powermock.googlecode.com/svn/repo'

SERVLET_API = 'javax.servlet:servlet-api:jar:2.5'
TC_VERSION = '6.0.28'
CATALINA = "org.apache.tomcat:catalina:jar:#{TC_VERSION}"
CATALINA_HA = "org.apache.tomcat:catalina-ha:jar:#{TC_VERSION}"
TC_COYOTE = transitive( "org.apache.tomcat:coyote:jar:#{TC_VERSION}" )
MEMCACHED = artifact('spy.memcached:spymemcached:jar:2.5').from(file('lib/memcached-2.5.jar'))
JAVOLUTION = artifact('javolution:javolution:jar:5.4.3.1').from(file('lib/javolution-5.4.3.1.jar'))
XSTREAM = transitive( 'com.thoughtworks.xstream:xstream:jar:1.3.1' )
JSR305 = 'com.google.code.findbugs:jsr305:jar:1.3.9'

# Kryo
KRYO_SERIALIZERS = artifact( 'de.javakaffee:kryoserializers:jar:0.8' ).from(file('lib/kryo-serializers-0.8.jar'))
KRYO = artifact( 'com.esotericsoftware:kryo:jar:1.03' ).from( file( 'lib/kryo-1.03.jar' ) )
REFLECTASM = artifact('com.esotericsoftware:reflectasm:jar:0.9').from(file('lib/reflectasm-0.9.jar'))
MINLOG = artifact('com.esotericsoftware:minlog:jar:1.2').from(file('lib/minlog-1.2.jar'))
ASM = 'asm:asm:jar:3.2'

# Custom converter libs
JODA_TIME = 'joda-time:joda-time:jar:1.6'
CGLIB = transitive( 'cglib:cglib:jar:2.2' )
WICKET = transitive( 'org.apache.wicket:wicket:jar:1.4.7' )
HIBERNATE = transitive( 'org.hibernate:hibernate-core:jar:3.3.2.GA' )
HIBERNATE_ANNOTATIONS = transitive( 'org.hibernate:hibernate-annotations:jar:3.4.0.GA' )
HSQLDB = transitive( 'hsqldb:hsqldb:jar:1.8.0.10' )
JAVASSIST = transitive( 'javassist:javassist:jar:3.11.0.GA' )
SPRING = group( 'spring-core', 'spring-beans', 'spring-aop', :under => 'org.springframework', :version => '2.5.6' )

# Testing
JMEMCACHED = transitive( 'com.thimbleware.jmemcached:jmemcached-core:jar:0.9.1' ).reject { |a| a.group == 'org.slf4j' }
HTTP_CLIENT = transitive( 'org.apache.httpcomponents:httpclient:jar:4.1-alpha1' )
SLF4J = transitive( 'org.slf4j:slf4j-simple:jar:1.5.6' )
JMOCK_CGLIB = transitive( 'jmock:jmock-cglib:jar:1.2.0' )
CLANG = 'commons-lang:commons-lang:jar:2.4' # tests of javolution-serializer, xstream-serializer
MOCKITO = transitive( 'org.mockito:mockito-core:jar:1.8.1' )

# Dependencies
require 'etc/tools'

LIBS = [ CATALINA, CATALINA_HA, MEMCACHED, JMEMCACHED, TC_COYOTE, HTTP_CLIENT, SLF4J, XSTREAM ]
task("check-deps") do |task|
  checkdeps LIBS      
end                         

task("dep-tree") do |task|
  deptree LIBS
end

desc 'memcached-session-manager (msm for short): memcached based session failover for Apache Tomcat'
define 'msm' do
  project.group = 'de.javakaffee.web.msm'
  project.version = '1.4.0-SNAPSHOT'

  compile.using :source=>'1.6', :target=>'1.6'
  test.using :testng
  package_with_javadoc

  checkstyle.config 'etc/checkstyle-checks.xml'
  checkstyle.style 'etc/checkstyle.xsl'

  desc 'The core module of memcached-session-manager'
  define 'core' do |project|
    compile.with( SERVLET_API, CATALINA, CATALINA_HA, TC_COYOTE, MEMCACHED, JSR305 )
    test.with( JMEMCACHED, HTTP_CLIENT, SLF4J, JMOCK_CGLIB, MOCKITO, HIBERNATE, HIBERNATE_ANNOTATIONS, JAVASSIST, HSQLDB )
    package :jar, :id => 'memcached-session-manager'
    package(:jar, :classifier => 'sources', :id => 'memcached-session-manager').include :from => compile.sources 
  end

  desc 'Javolution/xml based serialization strategy'
  define 'javolution-serializer' do |project|
    compile.with( projects('core'), project('core').compile.dependencies, JAVOLUTION, HIBERNATE, JODA_TIME, CGLIB )
    test.with( compile.dependencies, project('core').test.dependencies, CLANG, MOCKITO )
    package :jar, :id => 'msm-javolution-serializer'
    package(:jar, :classifier => 'sources', :id => 'msm-javolution-serializer').include :from => compile.sources 
  end

  desc 'XStream/xml based serialization strategy'
  define 'xstream-serializer' do |project|
    compile.with( projects('core'), project('core').compile.dependencies, XSTREAM )
    test.with( compile.dependencies, project('core').test.dependencies, CLANG )
    package :jar, :id => 'msm-xstream-serializer'
    package(:jar, :classifier => 'sources', :id => 'msm-xstream-serializer').include :from => compile.sources 
  end

  desc 'Kryo/binary serialization strategy'
  define 'kryo-serializer' do |project|
    compile.with( projects('core'), project('core').compile.dependencies, KRYO_SERIALIZERS, KRYO, REFLECTASM, ASM, MINLOG, JODA_TIME, WICKET, HIBERNATE, SPRING )
    test.with( project('core').test.dependencies, CLANG )
    package :jar, :id => 'msm-kryo-serializer'
    package(:jar, :classifier => 'sources', :id => 'msm-kryo-serializer').include :from => compile.sources 
  end

  desc 'Benchmark for serialization strategies'
  define 'serializer-benchmark' do |project|
    compile.with( projects('core'), project('core').compile.dependencies, projects('javolution-serializer'), project('javolution-serializer').compile.dependencies, projects('kryo-serializer'), project('kryo-serializer').compile.dependencies, CLANG )
    #test.with( compile.dependencies, CLANG )
    test.with( CLANG )
    package :jar, :id => 'msm-serializer-benchmark'
    package(:jar, :classifier => 'sources', :id => 'msm-serializer-benchmark').include :from => compile.sources 
  end

end
