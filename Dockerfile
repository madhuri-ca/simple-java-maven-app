# Step 1: Build stage (using Maven to compile & package the app)
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Step 2: Runtime stage (lightweight image with just JRE)
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copy the JAR built in the builder stage
COPY --from=builder /app/target/my-app-1.0-SNAPSHOT.jar app.jar

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
