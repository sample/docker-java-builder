How to use:
Create java directory and copy jre-8u<version>-linux-x64.tar or jdk-8u<version>-linux-x64.tar to ./java

`docker run -v $PWD/java:/java -v $PWD/target:/target -it --rm sample/docker-java-builder jre-8u60-linux-x64.tar`

Obtain ./oracle-jre8_<version>_amd64.deb package from ./target directory.
