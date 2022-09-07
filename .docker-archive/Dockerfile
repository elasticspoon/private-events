FROM ruby:3.1.2-slim
LABEL maintainer="ybocharov95@gmail.com"

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
  build-essential \
  gnupg2 \
  less \
  git \
  libpq-dev \
  postgresql-client \
  libvips42 \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

COPY Gemfile* /usr/src/app/
WORKDIR /usr/src/app

RUN bundle install

COPY . /usr/src/app/

EXPOSE 3000

ENTRYPOINT [ "./entrypoint.sh" ]

CMD ["bin/dev"]