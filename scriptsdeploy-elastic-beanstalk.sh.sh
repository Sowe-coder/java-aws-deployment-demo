#!/bin/bash

# Elastic Beanstalk Deployment Script
echo "Deploying to Elastic Beanstalk..."

# Configuration
APP_NAME="java-demo-app"
ENV_NAME="java-demo-env"
BUCKET_NAME="java-demo-deployments-$(date +%s)"
REGION="us-east-1"
PLATFORM="Java 11 running on 64bit Amazon Linux 2"

# Create S3 bucket for deployments
echo "Creating S3 bucket for deployments..."
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Build the application
echo "Building application..."
mvn clean package

# Upload to S3
echo "Uploading to S3..."
VERSION_LABEL="v-$(date +%Y%m%d%H%M%S)"
aws s3 cp target/demo-0.0.1-SNAPSHOT.jar s3://$BUCKET_NAME/$APP_NAME-$VERSION_LABEL.jar

# Create application version
echo "Creating application version..."
aws elasticbeanstalk create-application-version \
    --application-name $APP_NAME \
    --version-label $VERSION_LABEL \
    --source-bundle S3Bucket=$BUCKET_NAME,S3Key=$APP_NAME-$VERSION_LABEL.jar

# Create or update environment
if ! aws elasticbeanstalk describe-environments --application-name $APP_NAME --environment-names $ENV_NAME | grep -q "$ENV_NAME"; then
    echo "Creating new environment..."
    
    # Create IAM role for Elastic Beanstalk if not exists
    if ! aws iam get-role --role-name aws-elasticbeanstalk-service-role 2>/dev/null; then
        aws iam create-role \
            --role-name aws-elasticbeanstalk-service-role \
            --assume-role-policy-document file://infrastructure/iam-policies/eb-trust-policy.json
        
        aws iam attach-role-policy \
            --role-name aws-elasticbeanstalk-service-role \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService
        
        aws iam attach-role-policy \
            --role-name aws-elasticbeanstalk-service-role \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth
    fi
    
    # Create environment
    aws elasticbeanstalk create-environment \
        --application-name $APP_NAME \
        --environment-name $ENV_NAME \
        --version-label $VERSION_LABEL \
        --solution-stack-name "$PLATFORM" \
        --option-settings file://infrastructure/elastic-beanstalk/options.json \
        --service-role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/aws-elasticbeanstalk-service-role
else
    echo "Updating existing environment..."
    aws elasticbeanstalk update-environment \
        --application-name $APP_NAME \
        --environment-name $ENV_NAME \
        --version-label $VERSION_LABEL
fi

echo "========================================="
echo "Elastic Beanstalk Deployment Initiated!"
echo "========================================="
echo "Application: $APP_NAME"
echo "Environment: $ENV_NAME"
echo "Version: $VERSION_LABEL"
echo "Check status: aws elasticbeanstalk describe-environments --environment-names $ENV_NAME"
echo "========================================="