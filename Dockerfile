# Use a Node.js base image with minimal overhead
FROM node:18-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies
RUN apk add --no-cache git && npm install

# Copy the rest of the project files
COPY . .

# Build the Next.js app (separate stage for clarity)
FROM node:18-alpine

WORKDIR /app

COPY --from=builder /app .

RUN npm run build

# Expose the port for serving the app
EXPOSE 3000

# Start the Next.js app
CMD ["npm", "start"]