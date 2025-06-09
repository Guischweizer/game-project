#!/bin/bash

# Update and install dependencies
yum update -y
amazon-linux-extras install docker -y
service docker start
systemctl enable docker
usermod -a -G docker ec2-user
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
yum install git -y

# Install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn-archive-keyring.gpg >/dev/null
curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo
yum install yarn -y

# Clone repository
git clone ${repository_url} /home/ec2-user/game-project

# Create .env file for the backend
cat > /home/ec2-user/game-project/server/game-server/.env << EOL
DATABASE_URL=postgresql://${db_username}:${db_password}@${db_endpoint}/gameplatform
JWT_SECRET=${jwt_secret}
STRIPE_SECRET_KEY=${stripe_secret_key}
STRIPE_WEBHOOK_SECRET=${stripe_webhook_secret}
FRONTEND_URL=https://${cloudfront_domain}
EOL

# Create Docker Compose file if not exists
if [ ! -f /home/ec2-user/game-project/server/game-server/docker-compose.yml ]; then
  cat > /home/ec2-user/game-project/server/game-server/docker-compose.yml << EOL
version: '3'
services:
  backend:
    build: .
    ports:
      - "3000:3000"
    env_file:
      - .env
    restart: always
EOL
fi

# Create Dockerfile if not exists
if [ ! -f /home/ec2-user/game-project/server/game-server/Dockerfile ]; then
  cat > /home/ec2-user/game-project/server/game-server/Dockerfile << EOL
FROM node:16-alpine
WORKDIR /app
COPY package*.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build
EXPOSE 3000
CMD ["yarn", "start:prod"]
EOL
fi

# Setup and run the application
cd /home/ec2-user/game-project/server/game-server
yarn install
yarn prisma migrate deploy
docker-compose up -d

# Set up cron job to update application from git daily
echo "0 2 * * * cd /home/ec2-user/game-project && git pull && cd server/game-server && docker-compose up -d --build" | crontab -
