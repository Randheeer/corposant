#!/bin/bash

LOCK_FILE="/tmp/deploy.lock"

if [ -f "$LOCK_FILE" ]; then
  echo "Deployment already running. Skipping..."
  exit 0
fi

touch $LOCK_FILE

echo "Starting Application..."

echo "Pullng latest code..."
git pull origin main

VERSION=$(git rev-parse --short HEAD)
echo "Version:$VERSION"

echo " Building images..."

docker build -t corposant_backend:$VERSION ./backend
docker build -t corposant_nginx:$VERSION ./nginx
docker build -t corposant_frontend:$VERSION ./frontend

echo " Stopping all containers..."
docker-compose down 

echo " Starting new containers with versioning..."
VERSION=$VERSION docker-compose up -d

echo " Check nginx health..."

STATUS=$(docker inspect --format='{{.State.Health.Status}}' corposant-nginx)

echo "Health status:$STATUS"

if [ "$STATUS" != "healthy" ]; then
  echo"Deployment Failed!!"

  rm -f $LOCK_FILE

  exit 1
fi

  echo "Deployment successful!!!!"

  echo $VERSION > /tmp/current_version
  
  rm -f $LOCK_FILE
