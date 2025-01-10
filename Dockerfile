FROM amazoncorretto:17-alpine

# Install wget & unzip
RUN apk add --no-cache wget unzip

# Download & unzip Gradle
RUN wget 'https://services.gradle.org/distributions/gradle-8.10-all.zip?_gl=1*wewiwa*_gcl_au*MTMyODgzNjk1MC4xNzIzNjczNjk5*_ga*MTY5NzUzNTIyMC4xNzIzNjczNjk5*_ga_7W7NC6YNPT*MTcyMzY3MzY5OS4xLjEuMTcyMzY3NDM0MC42MC4wLjA.' -O gradle-8.10.zip && \
    unzip -d /opt/gradle gradle-8.10.zip && \
    rm gradle-8.10.zip

# Add Gradle to the PATH
ENV PATH=$PATH:/opt/gradle/gradle-8.10/bin

WORKDIR /ktor-users

COPY . .

# Build & run the application
RUN gradle build --no-daemon
CMD ["gradle", "run"]
