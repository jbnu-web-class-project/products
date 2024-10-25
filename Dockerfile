# STEP 1: Build Stage
FROM node:20-alpine AS builder

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json first
COPY package*.json ./

# Install all dependencies (including dev dependencies)
RUN npm install

# Copy the rest of the application source code
COPY . .

# Build the application
RUN npm run build



# STEP 2: Production Stage
FROM node:20-alpine

# Create app directory
WORKDIR /usr/src/app

# Set environment variable
ENV NODE_ENV=production

# Copy only the necessary files from builder stage
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/package*.json ./

# Install only production dependencies
RUN npm install --only=production && \
    npm cache clean --force

# Change to non-root user
RUN addgroup -S nest && adduser -S nest -G nest
USER nest

# Start the server using the production build
CMD ["node", "dist/main.js"]

# Expose the application port
EXPOSE 3000
