#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose-plugin git

sudo usermod -aG docker ubuntu
sudo systemctl enable docker  
sudo systemctl start docker