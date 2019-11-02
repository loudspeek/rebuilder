FROM ruby:2.4.0
RUN gem install bundler
WORKDIR /app
COPY Gemfile /app
COPY Gemfile.lock /app
RUN bundle install
COPY . /app

RUN apt-get update
RUN apt-get install -y locales
RUN sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LC_ALL en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en

CMD ["ruby", "./app.rb"]