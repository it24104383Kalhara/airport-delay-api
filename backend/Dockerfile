# ==========================================
# STAGE 1: Build the Go binary
# ==========================================
# Use a lightweight alpine image for building the Go application
FROM golang:alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy dependency management files first for better layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Statically compile the Go binary for Linux
# CGO_ENABLED=0 ensures the binary doesn't depend on C libraries
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# ==========================================
# STAGE 2: Minimal Runtime Image
# ==========================================
# Use a fresh, minimal alpine image for the final container
FROM alpine:latest  

# Install CA certificates so the app can communicate over HTTPS (e.g., to Supabase)
RUN apk --no-cache add ca-certificates

# ------------------------------------------
# Choreo Specific Configuration
# ------------------------------------------
# Create a non-root group and user with UID 10014 (Required by WSO2 Choreo)
RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

# Set the working directory for the runtime container
WORKDIR /app/

# Copy only the compiled binary from the builder stage
COPY --from=builder /app/main .

# Change file ownership to the non-root user
RUN chown -R choreouser:choreo /app

# Switch to the non-root user (Security best practice & Choreo requirement)
USER 10014

# Expose port 8080 (Standard for Choreo)
EXPOSE 8080

# Command to run the application
CMD ["./main"]