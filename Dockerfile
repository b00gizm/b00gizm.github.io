FROM ruby:2.3.1

RUN apt-get update -qq \
    && apt-get install -y \
      build-essential \
      nodejs \
    && apt-get autoremove \
    && apt-get clean

ADD . /app

WORKDIR /app

EXPOSE 4000

CMD ["jekyll", "serve", "--host", "0.0.0.0", "--watch", "--drafts"]
