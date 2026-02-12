import boto3
import subprocess
import json
from datetime import datetime

route53 = boto3.client('route53')
ec2 = boto3.client('ec2')

def create_hosted_zone(domain, dns_server_ip):
    """Create Route53 hosted zone"""
    
    # Create zone
    response = route53.create_hosted_zone(
        Name=domain,
        CallerReference=str(datetime.now().timestamp()),
        HostedZoneConfig={
            'Comment': f'Managed by Neo VPS for {domain}',
            'PrivateZone': False
        }
    )
    
    zone_id = response['HostedZone']['Id']
    nameservers = response['DelegationSet']['NameServers']
    
    print(f"✅ Created zone {domain}: {zone_id}")
    print(f"📍 Name servers: {nameservers}")
    
    return zone_id, nameservers

def create_dns_records(zone_id, domain, server_ip, ns1_ip, ns2_ip):
    """Create basic DNS records"""
    
    changes = [
        # A record for domain
        {
            'Action': 'CREATE',
            'ResourceRecordSet': {
                'Name': domain,
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': server_ip}]
            }
        },
        # WWW record
        {
            'Action': 'CREATE',
            'ResourceRecordSet': {
                'Name': f'www.{domain}',
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': server_ip}]
            }
        },
        # NS records for custom nameservers
        {
            'Action': 'CREATE',
            'ResourceRecordSet': {
                'Name': f'ns1.{domain}',
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': ns1_ip}]
            }
        },
        {
            'Action': 'CREATE',
            'ResourceRecordSet': {
                'Name': f'ns2.{domain}',
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': ns2_ip}]
            }
        },
        # MX record
        {
            'Action': 'CREATE',
            'ResourceRecordSet': {
                'Name': domain,
                'Type': 'MX',
                'TTL': 300,
                'ResourceRecords': [{'Value': f'10 mail.{domain}'}]
            }
        },
        # Mail A record
        {
            'Action': 'CREATE',
            'ResourceRecordSet': {
                'Name': f'mail.{domain}',
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': server_ip}]
            }
        }
    ]
    
    route53.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch={'Changes': changes}
    )
    
    print(f"✅ Created DNS records for {domain}")

def verify_dns_propagation(domain, expected_ip, max_retries=10):
    """Verify DNS is working"""
    import time
    
    for i in range(max_retries):
        try:
            result = subprocess.run(
                ['dig', '+short', domain, '@8.8.8.8'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if expected_ip in result.stdout:
                print(f"✅ DNS propagated for {domain}")
                return True
                
        except Exception as e:
            print(f"⏳ Waiting for DNS propagation... ({i+1}/{max_retries})")
            
        time.sleep(30)
    
    print(f"⚠️  DNS not yet propagated for {domain}")
    return False

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 5:
        print("Usage: create-zone.py <domain> <server_ip> <ns1_ip> <ns2_ip>")
        sys.exit(1)
    
    domain = sys.argv[1]
    server_ip = sys.argv[2]
    ns1_ip = sys.argv[3]
    ns2_ip = sys.argv[4]
    
    # Create zone
    zone_id, nameservers = create_hosted_zone(domain, ns1_ip)
    
    # Create records
    create_dns_records(zone_id, domain, server_ip, ns1_ip, ns2_ip)
    
    # Verify
    verify_dns_propagation(domain, server_ip)
    
    print("\n" + "="*50)
    print("🎉 DNS Setup Complete!")
    print("="*50)
    print(f"Domain: {domain}")
    print(f"Zone ID: {zone_id}")
    print(f"Name Servers: {', '.join(nameservers)}")
    print(f"Custom NS: ns1.{domain}, ns2.{domain}")
    print("="*50)