FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /workspace

COPY backend/.mvn ./backend/.mvn
COPY backend/mvnw ./backend/mvnw
COPY backend/mvnw.cmd ./backend/mvnw.cmd
COPY backend/pom.xml ./backend/pom.xml

RUN chmod +x ./backend/mvnw && ./backend/mvnw -f ./backend/pom.xml -q -DskipTests dependency:go-offline

COPY backend/src ./backend/src

RUN ./backend/mvnw -f ./backend/pom.xml -q -DskipTests package

FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /workspace/backend/target/betaup-backend-0.0.1-SNAPSHOT.jar ./app.jar

EXPOSE 8080

CMD ["java", "-jar", "/app/app.jar"]
