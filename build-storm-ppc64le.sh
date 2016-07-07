set -ex
export MAVEN_OPTS="-Xmx3000m"
mvn clean install -DskipTests 
cd storm-dist/binary && mvn package -Dgpg.skip=true

