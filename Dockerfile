# syntax=docker/dockerfile:1

# Multi-stage build for Java application
FROM eclipse-temurin:17-jdk-jammy as deps

WORKDIR /build

# Copy Maven wrapper with executable permissions
COPY mvnw mvnw
COPY .mvn/ .mvn/
RUN chmod +x mvnw

# Copy pom.xml for dependency download
COPY pom.xml .

# Download dependencies as a separate step for Docker caching
RUN ./mvnw dependency:go-offline -DskipTests

# Build stage
FROM deps as package

WORKDIR /build

# Copy source code
COPY ./src src/

# Build the application
RUN ./mvnw package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-jammy

# Create non-root user
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10001 \
    appuser

WORKDIR /app

# Copy the JAR file from build stage
COPY --from=package /build/target/*.jar app.jar

# Switch to non-root user
USER appuser

# Expose port (adjust if your app uses different port)
EXPOSE 8080

# Run the application
CMD ["java", "-jar", "app.jar"]