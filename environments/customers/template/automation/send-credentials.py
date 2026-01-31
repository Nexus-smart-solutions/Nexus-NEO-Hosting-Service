#!/usr/bin/env python3
"""
Automated Welcome Email Sender
Sends customer credentials and access information after provisioning
"""

import json
import argparse
import boto3
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime
import sys
import os

# ===================================
# CONFIGURATION
# ===================================

# SES configuration (set via environment or defaults)
SES_REGION = os.getenv('SES_REGION', 'us-east-1')
FROM_EMAIL = os.getenv('FROM_EMAIL', 'support@yourhosting.com')
FROM_NAME = os.getenv('FROM_NAME', 'Your Hosting Company')

# ===================================
# EMAIL TEMPLATE
# ===================================

def load_email_template():
    """Load HTML email template"""
    template_path = os.path.join(
        os.path.dirname(__file__),
        'templates',
        'welcome-email.html'
    )
    
    if os.path.exists(template_path):
        with open(template_path, 'r') as f:
            return f.read()
    
    # Default template if file doesn't exist
    return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .info-box { background: white; padding: 20px; margin: 20px 0; border-left: 4px solid #667eea; border-radius: 5px; }
        .info-box h3 { margin-top: 0; color: #667eea; }
        .credential { background: #e8f4f8; padding: 10px; margin: 10px 0; border-radius: 5px; font-family: monospace; }
        .button { display: inline-block; background: #667eea; color: white !important; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Welcome to Your cPanel Hosting!</h1>
            <p>Your hosting account is ready</p>
        </div>
        
        <div class="content">
            <h2>Hello!</h2>
            <p>Thank you for choosing our hosting services. Your cPanel hosting account for <strong>{{DOMAIN}}</strong> has been successfully provisioned and is now ready to use.</p>
            
            <div class="info-box">
                <h3>📍 Server Information</h3>
                <p><strong>Domain:</strong> {{DOMAIN}}</p>
                <p><strong>Server IP:</strong> <span class="credential">{{SERVER_IP}}</span></p>
                <p><strong>Nameservers:</strong></p>
                <div class="credential">
                    {{NAMESERVER_1}}<br>
                    {{NAMESERVER_2}}
                </div>
            </div>
            
            <div class="info-box">
                <h3>🔐 Access URLs</h3>
                <p><strong>WHM (Server Admin):</strong></p>
                <div class="credential">{{WHM_URL}}</div>
                <p><strong>cPanel (Account Management):</strong></p>
                <div class="credential">{{CPANEL_URL}}</div>
                <p><strong>Webmail:</strong></p>
                <div class="credential">{{WEBMAIL_URL}}</div>
            </div>
            
            <div class="info-box">
                <h3>👤 Login Credentials</h3>
                <p><strong>Username:</strong> <span class="credential">root</span></p>
                <p><strong>Password:</strong> <span class="credential">{{ROOT_PASSWORD}}</span></p>
                <p style="color: #dc3545; font-size: 12px;"><em>⚠️ Please change this password immediately after first login</em></p>
            </div>
            
            <div class="warning">
                <strong>⚠️ Important Next Steps:</strong>
                <ol>
                    <li><strong>Update DNS Records:</strong> Point your domain's nameservers to the ones provided above</li>
                    <li><strong>Change Root Password:</strong> Access WHM and change the root password immediately</li>
                    <li><strong>Install cPanel License:</strong> Enter your cPanel license key in WHM</li>
                    <li><strong>Configure SSL:</strong> Enable AutoSSL for free HTTPS certificates</li>
                    <li><strong>Set up Email:</strong> Configure your email accounts in cPanel</li>
                </ol>
            </div>
            
            <div class="info-box">
                <h3>📚 Getting Started</h3>
                <p>Need help getting started? Check out these resources:</p>
                <ul>
                    <li><a href="https://docs.cpanel.net/">cPanel Documentation</a></li>
                    <li><a href="https://support.yourhosting.com">Our Support Center</a></li>
                    <li><a href="https://support.yourhosting.com/tutorials">Video Tutorials</a></li>
                </ul>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="{{WHM_URL}}" class="button">Access WHM</a>
                <a href="{{CPANEL_URL}}" class="button">Access cPanel</a>
            </div>
            
            <div class="info-box">
                <h3>💬 Need Help?</h3>
                <p>Our support team is here to help you 24/7:</p>
                <p>📧 Email: <a href="mailto:support@yourhosting.com">support@yourhosting.com</a></p>
                <p>💬 Live Chat: <a href="https://yourhosting.com/support">yourhosting.com/support</a></p>
                <p>📞 Phone: +1 (555) 123-4567</p>
            </div>
        </div>
        
        <div class="footer">
            <p>© {{YEAR}} Your Hosting Company. All rights reserved.</p>
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
"""

def generate_root_password():
    """Generate secure random password"""
    import secrets
    import string
    
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    password = ''.join(secrets.choice(alphabet) for i in range(16))
    return password

def send_email(to_email, subject, html_body, text_body=None):
    """Send email via AWS SES"""
    ses_client = boto3.client('ses', region_name=SES_REGION)
    
    try:
        response = ses_client.send_email(
            Source=f'"{FROM_NAME}" <{FROM_EMAIL}>',
            Destination={'ToAddresses': [to_email]},
            Message={
                'Subject': {'Data': subject, 'Charset': 'UTF-8'},
                'Body': {
                    'Html': {'Data': html_body, 'Charset': 'UTF-8'},
                    'Text': {'Data': text_body or 'Please view this email in HTML format', 'Charset': 'UTF-8'}
                }
            }
        )
        return response
    except Exception as e:
        print(f"Error sending email: {e}", file=sys.stderr)
        raise

def main():
    parser = argparse.ArgumentParser(description='Send customer welcome email')
    parser.add_argument('--domain', required=True, help='Customer domain')
    parser.add_argument('--email', required=True, help='Customer email address')
    parser.add_argument('--outputs', required=True, help='Path to Terraform outputs.json')
    parser.add_argument('--password', help='Root password (generated if not provided)')
    
    args = parser.parse_args()
    
    # Load Terraform outputs
    with open(args.outputs, 'r') as f:
        outputs = json.load(f)
    
    # Extract values
    server_ip = outputs.get('server_ip', {}).get('value', 'N/A')
    whm_url = outputs.get('whm_url', {}).get('value', 'N/A')
    cpanel_url = outputs.get('cpanel_url', {}).get('value', 'N/A')
    webmail_url = outputs.get('webmail_url', {}).get('value', 'N/A')
    nameservers = outputs.get('nameservers', {}).get('value', ['N/A', 'N/A'])
    
    # Generate or use provided password
    root_password = args.password or generate_root_password()
    
    # Store password securely (in production, use AWS Secrets Manager)
    password_file = os.path.join(
        os.path.dirname(args.outputs),
        'root_password.txt'
    )
    with open(password_file, 'w') as f:
        f.write(root_password)
    os.chmod(password_file, 0o600)
    
    print(f"Root password saved to: {password_file}")
    
    # Load and populate template
    template = load_email_template()
    html_body = template.replace('{{DOMAIN}}', args.domain)
    html_body = html_body.replace('{{SERVER_IP}}', server_ip)
    html_body = html_body.replace('{{WHM_URL}}', whm_url)
    html_body = html_body.replace('{{CPANEL_URL}}', cpanel_url)
    html_body = html_body.replace('{{WEBMAIL_URL}}', webmail_url)
    html_body = html_body.replace('{{NAMESERVER_1}}', nameservers[0] if len(nameservers) > 0 else 'N/A')
    html_body = html_body.replace('{{NAMESERVER_2}}', nameservers[1] if len(nameservers) > 1 else 'N/A')
    html_body = html_body.replace('{{ROOT_PASSWORD}}', root_password)
    html_body = html_body.replace('{{YEAR}}', str(datetime.now().year))
    
    subject = f"Welcome to Your cPanel Hosting - {args.domain}"
    
    # Send email
    print(f"Sending welcome email to {args.email}...")
    response = send_email(args.email, subject, html_body)
    
    print(f"Email sent successfully!")
    print(f"Message ID: {response['MessageId']}")
    print(f"\nIMPORTANT: Root password has been saved to {password_file}")
    print("Please securely share this with the customer through a separate channel.")

if __name__ == '__main__':
    main()
