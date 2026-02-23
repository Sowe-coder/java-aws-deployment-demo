#!/bin/bash

# RDS Setup Script
echo "Setting up RDS Database..."

# Configuration
DB_INSTANCE_IDENTIFIER="java-demo-db"
DB_NAME="userdb"
DB_USERNAME="admin"
DB_PASSWORD=$(openssl rand -base64 32 | tr -d /=+ | cut -c -16)
DB_INSTANCE_CLASS="db.t3.micro"
ENGINE="mysql"
ENGINE_VERSION="8.0.33"
STORAGE=20

# Create security group for RDS
echo "Creating security group for RDS..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 create-security-group \
    --group-name "rds-demo-sg" \
    --description "Security group for RDS demo" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)

# Add inbound rule for MySQL
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0

# Create RDS instance
echo "Creating RDS instance (this will take a few minutes)..."
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine $ENGINE \
    --engine-version $ENGINE_VERSION \
    --master-username $USERNAME \
    --master-user-password $PASSWORD \
    --allocated-storage $STORAGE \
    --db-name $DB_NAME \
    --vpc-security-group-ids $SG_ID \
    --publicly-accessible \
    --backup-retention-period 1 \
    --no-multi-az \
    --auto-minor-version-upgrade

# Wait for instance to be available
echo "Waiting for RDS instance to become available..."
aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_IDENTIFIER

# Get connection details
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

DB_PORT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --query 'DBInstances[0].Endpoint.Port' \
    --output text)

# Save credentials to a secure file
cat > ~/rds-credentials.txt << EOF
Database: $DB_NAME
Username: $DB_USERNAME
Password: $DB_PASSWORD
Host: $DB_ENDPOINT
Port: $DB_PORT
Connection String: mysql://$DB_USERNAME:$DB_PASSWORD@$DB_ENDPOINT:$DB_PORT/$DB_NAME
EOF

chmod 600 ~/rds-credentials.txt

echo "========================================="
echo "RDS Setup Complete!"
echo "========================================="
echo "Database Host: $DB_ENDPOINT"
echo "Database Port: $DB_PORT"
echo "Database Name: $DB_NAME"
echo "Username: $DB_USERNAME"
echo "Password: $DB_PASSWORD"
echo ""
echo "Credentials saved to: ~/rds-credentials.txt"
echo "========================================="