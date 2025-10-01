# Use official Node.js 20 image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy rest of the code
COPY . .

# Build for production
RUN yarn build

# Expose Medusa default port
EXPOSE 9000

# Start Medusa app in production mode
CMD ["yarn", "start"]