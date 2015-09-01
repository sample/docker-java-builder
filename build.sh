#!/bin/bash

mkdir -p /build
mkdir -p /target

tar xvf /java/$1 -C /build
JAVA_DIRECTORY=`ls -1 /build`

# Transform jdk1.8.0_60 to 1.8.0.60
JAVA_VERSION=$(echo $JAVA_DIRECTORY | sed -nr 's/([a-zA-Z]+)([0-9])\.([0-9]+)\.([0-9]+)\_([0-9]+).*/\2.\3.\4.\5/p')
JAVA_VARIANT=$(echo $JAVA_DIRECTORY | sed -nr 's/([a-zA-Z]+)[0-9].*/\1/p')
JAVA_MAJOR_VERSION=$(echo $JAVA_DIRECTORY | sed -nr 's/[a-zA-Z]+[0-9]\.([0-9]+)\..*/\1/p')
SDK_VERSION=$JAVA_DIRECTORY

cd /target

cat <<EOF > alternatives.sh
#!/bin/bash
/usr/bin/update-alternatives --install /usr/bin/java java /opt/$SDK_VERSION/bin/java 1
EOF

cat <<EOF > uninstall.sh
#!/bin/bash
/usr/bin/update-alternatives --remove java /opt/$SDK_VERSION/bin/java
rm -rf /opt/$SDK_VERSION
EOF

JRE_PROVIDES='java-runtime java2-runtime java5-runtime java6-runtime java7-runtime java8-runtime'
JDK_PROVIDES='java-compiler java-sdk java2-sdk java5-sdk java6-sdk java7-jdk java8-jdk'

PROVIDES=""
if [ $JAVA_VARIANT == 'jdk' ]; then
  for i in `echo $JDK_PROVIDES`; do PROVIDES+="--provides $i "; done
else
  for i in `echo $JRE_PROVIDES`; do PROVIDES+="--provides $i "; done
fi

fpm -f --verbose -s dir -t deb --after-install ./alternatives.sh --after-remove ./uninstall.sh --name oracle-$JAVA_VARIANT$JAVA_MAJOR_VERSION $PROVIDES -v $JAVA_VERSION --prefix=/opt/ -C /build $SDK_VERSION

rm -f alternatives.sh uninstall.sh
