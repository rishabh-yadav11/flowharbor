# ---- Build & Test stage ----
FROM node:20-alpine AS build

WORKDIR /app

# Install deps first for better layer caching
COPY package*.json ./
RUN npm ci

# Copy source and run the test suite — image build fails if tests fail
COPY . .
RUN npm test

# ---- Runtime stage ----
FROM node:20-alpine AS runtime

WORKDIR /app
ENV NODE_ENV=production

# Only install production deps in the final image
COPY package*.json ./
RUN npm ci --omit=dev

# Copy application source from the build stage (already verified by tests)
COPY --from=build /app/src ./src

EXPOSE 3000
CMD ["node", "src/server.js"]
