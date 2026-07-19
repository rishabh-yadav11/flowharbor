FROM nginx:alpine

# Remove default nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy your static site files into nginx's web root
COPY . /usr/share/nginx/html

EXPOSE 80
