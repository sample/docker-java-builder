FROM ruby:2.2.3-onbuild

COPY build.sh /

WORKDIR /

ENTRYPOINT ["/build.sh"]
