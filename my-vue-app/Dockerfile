# Stage 1: Build Vue app
FROM node:20-alpine AS build

WORKDIR /app

# Copy package files và install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy source code và build
COPY . .
RUN npm run build

# Stage 2: Serve bằng Nginx
FROM nginx:alpine

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files từ stage 1
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
