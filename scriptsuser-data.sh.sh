#!/bin/bash
# User data script for EC2 instance initialization

# Update system
yum update -y

# Install Java
amazon-linux-extras enable java-openjdk11
yum install -y java-11-openjdk-devel

# Install Git
yum install -y git

# Create application directory
mkdir -p /opt/application
cd /opt/application

# Clone repository (replace with your repo)
# git clone https://github.com/yourusername/java-aws-deployment-demo.git

# For demo, we'll create a simple script to download the JAR
# This should be replaced with actual deployment mechanism

# Create systemd service
cat > /etc/systemd/system/java-app.service << EOF
[Unit]
Description=Java Spring Boot Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/application
ExecStart=/usr/bin/java -jar /opt/application/app.jar
Restart=on-failure
Environment="RDS_HOSTNAME=${RDS_HOSTNAME}"
Environment="RDS_PORT=${RDS_PORT}"
Environment="RDS_DB_NAME=${RDS_DB_NAME}"
Environment="RDS_USERNAME=${RDS_USERNAME}"
Environment="RDS_PASSWORD=${RDS_PASSWORD}"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl enable java-app.service