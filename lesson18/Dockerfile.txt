# Use Alpine as the base image
FROM alpine:latest

# Install Nginx
RUN apk add --update nginx

# Copy custom HTML page to Nginx default location
COPY custom_page.html /usr/share/nginx/html/index.html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/http.d/default.conf

# Expose port 80 for web traffic
EXPOSE 80

# Start Nginx server when the container starts
CMD ["nginx", "-g", "daemon off;"]
