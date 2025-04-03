FROM maven:3.9.8-eclipse-temurin-21 AS build

WORKDIR /app
COPY pom.xml .
COPY src ./src

RUN mvn clean install -DskipTests

FROM openjdk:21

COPY --from=build /app/target/meditrack-project.jar /app/meditrack-project.jar

WORKDIR /app

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "meditrack-project.jar"]