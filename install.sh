#!/bin/bash


echo "Installing python3-pip and docker."
sudo apt update
sudo apt install -y python3-pip docker.io

echo "Writing Dockerfile..."
cat <<EOF > Dockerfile
FROM ubuntu:22.04

RUN apt update
RUN apt install -y tmate
EOF

echo "Building Docker Image"
sudo docker build -t ubuntu-22.04-with-tmate .
echo "Downloading main.py from the GitHub repository..."
wget -O main.py https://raw.githubusercontent.com/katy-the-kat/discord-vps-creator/refs/heads/main/v3ds
echo "Installing Python packages: discord and docker..."
pip3 install discord docker
echo "Please enter your Discord bot token:"
read -r DISCORD_TOKEN
echo "Updating main.py with the provided Discord token..."
sed -i "s/TOKEN = ''/TOKEN = '$DISCORD_TOKEN'/" main.py
echo "Starting the Discord bot..."
echo "To start the bot in the future, run: python3 main.py"
python3 main.py
