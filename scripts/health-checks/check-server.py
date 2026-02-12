import boto3
import requests
import subprocess
import json
from datetime import datetime

ec2 = boto3.client('ec2')
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

table = dynamodb.Table('neo-instances')

def check_ec2_status(instance_id):
    """Check EC2 instance status"""
    response = ec2.describe_instance_status(InstanceIds=[instance_id])
    
    if not response['InstanceStatuses']:
        return False, "Instance not found"
    
    status = response['InstanceStatuses'][0]
    
    instance_ok = status['InstanceStatus']['Status'] == 'ok'
    system_ok = status['SystemStatus']['Status'] == 'ok'
    
    return (instance_ok and system_ok), status

def check_panel_http(ip, panel_type):
    """Check if control panel is responding"""
    ports = {
        'cpanel': 2087,
        'cyberpanel': 8090,
        'directadmin': 2222
    }
    
    if panel_type not in ports:
        return True, "No panel to check"
    
    port = ports[panel_type]
    
    try:
        response = requests.get(
            f'https://{ip}:{port}',
            timeout=10,
            verify=False
        )
        return response.status_code in [200, 302, 401], f"HTTP {response.status_code}"
    except Exception as e:
        return False, str(e)

def check_dns_resolution(domain):
    """Check if DNS is resolving"""
    try:
        result = subprocess.run(
            ['dig', '+short', domain, '@8.8.8.8'],
            capture_output=True,
            text=True,
            timeout=5
        )
        return bool(result.stdout.strip()), result.stdout.strip()
    except:
        return False, "DNS query failed"

def update_health_status(instance_id, health_data):
    """Update DynamoDB with health status"""
    table.update_item(
        Key={'instance_id': instance_id},
        UpdateExpression='SET health_status = :health, last_health_check = :time',
        ExpressionAttributeValues={
            ':health': health_data,
            ':time': datetime.utcnow().isoformat()
        }
    )

def send_alert(subject, message):
    """Send SNS alert"""
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:ACCOUNT:neo-alerts',
        Subject=subject,
        Message=message
    )

def run_health_check(instance_id):
    """Run complete health check"""
    
    print(f"🔍 Running health check for {instance_id}")
    
    # Get instance details from DynamoDB
    response = table.get_item(Key={'instance_id': instance_id})
    item = response['Item']
    
    domain = item['domain']
    public_ip = item['public_ip']
    panel = item['panel']
    
    health_data = {
        'timestamp': datetime.utcnow().isoformat(),
        'checks': {}
    }
    
    # Check 1: EC2 Status
    ec2_ok, ec2_status = check_ec2_status(instance_id)
    health_data['checks']['ec2_status'] = {
        'ok': ec2_ok,
        'details': str(ec2_status)
    }
    print(f"  EC2 Status: {'✅' if ec2_ok else '❌'}")
    
    # Check 2: Panel HTTP
    panel_ok, panel_status = check_panel_http(public_ip, panel)
    health_data['checks']['panel_http'] = {
        'ok': panel_ok,
        'details': panel_status
    }
    print(f"  Panel HTTP: {'✅' if panel_ok else '❌'}")
    
    # Check 3: DNS Resolution
    dns_ok, dns_result = check_dns_resolution(domain)
    health_data['checks']['dns_resolution'] = {
        'ok': dns_ok,
        'details': dns_result
    }
    print(f"  DNS: {'✅' if dns_ok else '❌'}")
    
    # Overall health
    all_ok = ec2_ok and panel_ok and dns_ok
    health_data['overall'] = 'healthy' if all_ok else 'unhealthy'
    
    # Update DynamoDB
    update_health_status(instance_id, health_data)
    
    # Alert if unhealthy
    if not all_ok:
        send_alert(
            f"⚠️ Health Check Failed: {domain}",
            f"Instance {instance_id} ({domain}) failed health checks:\n\n" +
            json.dumps(health_data, indent=2)
        )
    
    return all_ok

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: check-server.py <instance_id>")
        sys.exit(1)
    
    instance_id = sys.argv[1]
    healthy = run_health_check(instance_id)
    
    sys.exit(0 if healthy else 1)