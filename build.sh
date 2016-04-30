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
LATEST=1
LATEST=$((`LANG=C update-alternatives --display java | grep ^/ | sed -e 's/.* //g' | sort -n | tail -1`+1))
EOF

cat <<EOF > uninstall.sh
#!/bin/bash
rm -rf /opt/$SDK_VERSION
EOF

for f in /build/$JAVA_DIRECTORY/bin/*; do
        name=`basename $f`;
        if [ ! -f "/usr/bin/$name" -o -L "/usr/bin/$name" ]; then
                # Some files, like jvisualvm might not be links
                if [ -f "/build/$JAVA_DIRECTORY/man/man1/$name.1" ]; then
                        echo $name
                        echo update-alternatives --install /usr/bin/$name $name /opt/$JAVA_DIRECTORY/bin/$name \$LATEST \
                                --slave /usr/share/man/man1/$name.1 $name.1 /opt/$JAVA_DIRECTORY/man/man1/$name.1 >> alternatives.sh
                        #echo "jdk $name /opt/$JAVA_DIRECTORY/bin/$name" >> /usr/lib/jvm/.java-8-oracle.jinfo
                fi
        fi
done


for f in /build/$JAVA_DIRECTORY/man/man1/*; do
        name=`basename $f .1`;
        # Some files, like jvisualvm might not be links.
        # Further assume this for corresponding man page
        if [ ! -f "/usr/bin/$name" -o -L "/usr/bin/$name" ]; then
                echo $name
                echo update-alternatives --remove $name /opt/$JAVA_DIRECTORY/bin/$name >> uninstall.sh
        fi
done

JRE_PROVIDES='java-virtual-machine java-compiler default-jre default-jre-headless
          java-runtime java2-runtime java5-runtime java6-runtime java8-runtime
          java-runtime-headless java2-runtime-headless java5-runtime-headless java6-runtime-headless java8-runtime-headless
          openjdk-6-jre openjdk-6-jre-headless
          openjdk-7-jre openjdk-7-jre-headless
          openjdk-8-jre openjdk-8-jre-headless
          sun-java6-bin sun-java6-jre sun-java6-fonts sun-java6-plugin
          oracle-java7-bin oracle-java7-jre oracle-java7-fonts oracle-java7-plugin
          oracle-java8-bin oracle-java8-jre oracle-java8-fonts oracle-java8-plugin'

JDK_PROVIDES='java-virtual-machine java-compiler default-jre default-jdk default-jdk-headless
          java-runtime java2-runtime java5-runtime java6-runtime java8-runtime
          java-runtime-headless java2-runtime-headless java5-runtime-headless java6-runtime-headless java8-runtime-headless
          java-jdk java2-jdk java5-jdk java6-jdk java8-jdk
          java-sdk java2-sdk java5-sdk java6-sdk java8-sdk
          openjdk-6-jre openjdk-6-jre-headless openjdk-6-jdk openjdk-6-jdk-headless openjdk-6-jdk
          openjdk-7-jre openjdk-7-jre-headless openjdk-6-jdk openjdk-6-jdk-headless openjdk-6-jdk
          openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless openjdk-8-jdk
          sun-java6-bin sun-java6-jdk sun-java6-jdk sun-java6-fonts sun-java6-plugin
          oracle-java8-bin oracle-java8-fonts oracle-java8-plugin'

PROVIDES=""
if [ $JAVA_VARIANT == 'jdk' ]; then
  for i in `echo $JDK_PROVIDES`; do PROVIDES+="--provides $i "; done
  PKG_NAME=oracle-java8-jdk
else
  for i in `echo $JRE_PROVIDES`; do PROVIDES+="--provides $i "; done
  PKG_NAME=oracle-java8
fi

fpm -f --verbose -s dir -t deb --after-install ./alternatives.sh --after-remove ./uninstall.sh --name "$PKG_NAME" $PROVIDES -v $JAVA_VERSION --prefix=/opt/ -C /build/ $SDK_VERSION

rm -f alternatives.sh uninstall.sh
