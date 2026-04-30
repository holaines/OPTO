FROM docker.io/library/node:20-alpine
WORKDIR /app
COPY package*.json ./
# No dependencies to install, but good practice
COPY . .
CMD ["node", "server.js"]
