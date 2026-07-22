# ==========================================
# STAGE 1: Build the Go binary
# ==========================================
FROM golang:1.26.5-alpine AS builder

# Set workspace directory
WORKDIR /app

# Copy dependency management files first (for Docker layer caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Statically compile the Go binary for Linux
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# ==========================================
# STAGE 2: Minimal Runtime Image
# ==========================================
FROM alpine:latest  

# Install CA certificates so our app can communicate over HTTPS (to Supabase)
RUN apk --no-cache add ca-certificates

# Create a non-root group and user with UID 10014 (Required by Choreo)
RUN addgroup -g 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

WORKDIR /app/

# Copy only the compiled binary from Stage 1
COPY --from=builder /app/main .

# Change file ownership to the non-root user
RUN chown -R choreouser:choreo /app

# Switch to the non-root user
USER 10014

# Expose port 8080
EXPOSE 8080

# Command to run the application
CMD ["./main"]