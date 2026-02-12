#!/usr/bin/env python3
"""
Neo VPS DNS Automation Tool
Automates DNS zone creation and management for customer domains
"""

import boto3
import subprocess
import json
import time
import sys
from datetime import datetime
from typing import Dict, List, Tuple, Optional

# AWS Clients
route53 = boto3.client('route53')
ec2 = boto3.client('ec2')
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

class DNSAutomation:
    """DNS automation for Neo VPS platform"""
    
    def __init__(self, domain: str, server_ip: str, ns1_ip: str, ns2_ip: Optional[str] = None):
        self.domain = domain
        self.server_ip = server_ip
        self.ns1_ip = ns1_ip
        self.ns2_ip = ns2_ip
        self.zone_id = None
        self.nameservers = []
        
    def create_hosted_zone(self) -> Tuple[str, List[str]]:
        """Create Route53 hosted zone"""
        
        print(f"📍 Creating Route53 hosted zone for {self.domain}")
        
        try:
            response = route53.create_hosted_zone(
                Name=self.domain,
                CallerReference=str(datetime.now().timestamp()),
                HostedZoneConfig={
                    'Comment': f'Managed by Neo VPS Platform - {datetime.now().strftime("%Y-%m-%d")}',
                    'PrivateZone': False
                }
            )
            
            self.zone_id = response['HostedZone']['Id'].split('/')[-1]
            self.nameservers = response['DelegationSet']['NameServers']
            
            print(f"✅ Created hosted zone: {self.zone_id}")
            print(f"📌 AWS Nameservers: {', '.join(self.nameservers)}")
            
            return self.zone_id, self.nameservers
            
        except route53.exceptions.HostedZoneAlreadyExists:
            print(f"⚠️  Hosted zone already exists for {self.domain}")
            # Get existing zone
            zones = route53.list_hosted_zones_by_name(DNSName=self.domain)
            for zone in zones['HostedZones']:
                if zone['Name'].rstrip('.') == self.domain:
                    self.zone_id = zone['Id'].split('/')[-1]
                    break
            return self.zone_id, []
            
        except Exception as e:
            print(f"❌ Error creating hosted zone: {e}")
            raise
    
    def create_dns_records(self):
        """Create comprehensive DNS records"""
        
        if not self.zone_id:
            raise ValueError("Zone ID not set. Call create_hosted_zone() first.")
        
        print(f"📝 Creating DNS records for {self.domain}")
        
        changes = []
        
        # Main domain A record
        changes.append({
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': self.domain,
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': self.server_ip}]
            }
        })
        
        # WWW subdomain
        changes.append({
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': f'www.{self.domain}',
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': self.server_ip}]
            }
        })
        
        # Custom nameserver A records
        changes.append({
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': f'ns1.{self.domain}',
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': self.ns1_ip}]
            }
        })
        
        if self.ns2_ip:
            changes.append({
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': f'ns2.{self.domain}',
                    'Type': 'A',
                    'TTL': 300,
                    'ResourceRecords': [{'Value': self.ns2_ip}]
                }
            })
        
        # Mail records
        changes.append({
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': f'mail.{self.domain}',
                'Type': 'A',
                'TTL': 300,
                'ResourceRecords': [{'Value': self.server_ip}]
            }
        })
        
        changes.append({
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': self.domain,
                'Type': 'MX',
                'TTL': 300,
                'ResourceRecords': [{'Value': f'10 mail.{self.domain}'}]
            }
        })
        
        # Common subdomains (CNAME)
        for subdomain in ['ftp', 'webmail', 'cpanel', 'whm']:
            changes.append({
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': f'{subdomain}.{self.domain}',
                    'Type': 'CNAME',
                    'TTL': 300,
                    'ResourceRecords': [{'Value': self.domain}]
                }
            })
        
        # SPF record
        changes.append({
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': self.domain,
                'Type': 'TXT',
                'TTL': 300,
                'ResourceRecords': [{'Value': f'"v=spf1 a mx ip4:{self.server_ip} ~all"'}]
            }
        })
        
        # DMARC record
        changes.append({
            'Action': 'UPSERT',
            'ResourceRecordSet': {
                'Name': f'_dmarc.{self.domain}',
                'Type': 'TXT',
                'TTL': 300,
                'ResourceRecords': [{'Value': f'"v=DMARC1; p=none; rua=mailto:admin@{self.domain}"'}]
            }
        })
        
        # Apply all changes
        try:
            response = route53.change_resource_record_sets(
                HostedZoneId=self.zone_id,
                ChangeBatch={'Changes': changes}
            )
            
            change_id = response['ChangeInfo']['Id']
            print(f"✅ Created {len(changes)} DNS records")
            print(f"📌 Change ID: {change_id}")
            
            return change_id
            
        except Exception as e:
            print(f"❌ Error creating DNS records: {e}")
            raise
    
    def verify_dns_propagation(self, max_retries: int = 10, delay: int = 30) -> bool:
        """Verify DNS propagation"""
        
        print(f"🔍 Verifying DNS propagation for {self.domain}")
        
        for attempt in range(1, max_retries + 1):
            try:
                # Test against Google DNS
                result = subprocess.run(
                    ['dig', '+short', self.domain, '@8.8.8.8'],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                if self.server_ip in result.stdout:
                    print(f"✅ DNS propagated successfully! ({self.domain} → {self.server_ip})")
                    return True
                
                print(f"⏳ Waiting for DNS propagation... (attempt {attempt}/{max_retries})")
                
                if attempt < max_retries:
                    time.sleep(delay)
                    
            except subprocess.TimeoutExpired:
                print(f"⚠️  DNS query timeout (attempt {attempt}/{max_retries})")
            except Exception as e:
                print(f"❌ Error during DNS verification: {e}")
        
        print(f"⚠️  DNS not fully propagated after {max_retries} attempts")
        print(f"   This is normal - full propagation can take 24-48 hours")
        return False
    
    def test_nameservers(self) -> Dict[str, bool]:
        """Test custom nameservers"""
        
        print(f"🧪 Testing custom nameservers")
        
        results = {}
        
        # Test ns1
        try:
            result = subprocess.run(
                ['dig', f'@{self.ns1_ip}', self.domain, '+short'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            results['ns1'] = self.server_ip in result.stdout
            status = "✅" if results['ns1'] else "❌"
            print(f"  {status} ns1.{self.domain} ({self.ns1_ip})")
            
        except Exception as e:
            results['ns1'] = False
            print(f"  ❌ ns1.{self.domain} - Error: {e}")
        
        # Test ns2 if present
        if self.ns2_ip:
            try:
                result = subprocess.run(
                    ['dig', f'@{self.ns2_ip}', self.domain, '+short'],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                results['ns2'] = self.server_ip in result.stdout
                status = "✅" if results['ns2'] else "❌"
                print(f"  {status} ns2.{self.domain} ({self.ns2_ip})")
                
            except Exception as e:
                results['ns2'] = False
                print(f"  ❌ ns2.{self.domain} - Error: {e}")
        
        return results
    
    def save_to_dynamodb(self, table_name: str = 'neo-dns-zones'):
        """Save DNS configuration to DynamoDB"""
        
        print(f"💾 Saving DNS configuration to DynamoDB")
        
        try:
            table = dynamodb.Table(table_name)
            
            item = {
                'domain': self.domain,
                'zone_id': self.zone_id,
                'server_ip': self.server_ip,
                'ns1_ip': self.ns1_ip,
                'ns1_hostname': f'ns1.{self.domain}',
                'nameservers': self.nameservers,
                'created_at': datetime.utcnow().isoformat(),
                'status': 'active'
            }
            
            if self.ns2_ip:
                item['ns2_ip'] = self.ns2_ip
                item['ns2_hostname'] = f'ns2.{self.domain}'
            
            table.put_item(Item=item)
            
            print(f"✅ Saved to DynamoDB table: {table_name}")
            
        except Exception as e:
            print(f"⚠️  DynamoDB save failed (non-critical): {e}")
    
    def send_notification(self, sns_topic_arn: str, customer_email: str):
        """Send completion notification"""
        
        print(f"📧 Sending notification")
        
        message = f"""
DNS Configuration Complete for {self.domain}
{'='*60}

Domain: {self.domain}
Server IP: {self.server_ip}

CUSTOM NAMESERVERS:
  ns1.{self.domain} → {self.ns1_ip}
"""
        
        if self.ns2_ip:
            message += f"  ns2.{self.domain} → {self.ns2_ip}\n"
        
        message += f"""
ROUTE53 NAMESERVERS (temporary):
  {', '.join(self.nameservers[:2])}

{'='*60}
NEXT STEPS:
{'='*60}

1. Update nameservers at your domain registrar:
   - Set ns1.{self.domain} ({self.ns1_ip})
"""
        
        if self.ns2_ip:
            message += f"   - Set ns2.{self.domain} ({self.ns2_ip})\n"
        
        message += f"""
2. Wait 24-48 hours for full propagation

3. Verify with:
   dig NS {self.domain}
   dig @{self.ns1_ip} {self.domain}

{'='*60}
Setup completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}
{'='*60}
"""
        
        try:
            sns.publish(
                TopicArn=sns_topic_arn,
                Subject=f"✅ DNS Ready: {self.domain}",
                Message=message
            )
            
            print(f"✅ Notification sent to SNS topic")
            
        except Exception as e:
            print(f"⚠️  SNS notification failed (non-critical): {e}")
    
    def generate_report(self) -> str:
        """Generate setup report"""
        
        report = f"""
{'='*60}
DNS AUTOMATION REPORT
{'='*60}

Domain: {self.domain}
Setup Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

INFRASTRUCTURE:
  Server IP: {self.server_ip}
  Route53 Zone ID: {self.zone_id}

CUSTOM NAMESERVERS:
  Primary: ns1.{self.domain} ({self.ns1_ip})
"""
        
        if self.ns2_ip:
            report += f"  Secondary: ns2.{self.domain} ({self.ns2_ip})\n"
        
        report += f"""
AWS NAMESERVERS:
  {chr(10).join(f'  - {ns}' for ns in self.nameservers)}

DNS RECORDS CREATED:
  ✅ A record: {self.domain} → {self.server_ip}
  ✅ A record: www.{self.domain} → {self.server_ip}
  ✅ A record: mail.{self.domain} → {self.server_ip}
  ✅ A record: ns1.{self.domain} → {self.ns1_ip}
"""
        
        if self.ns2_ip:
            report += f"  ✅ A record: ns2.{self.domain} → {self.ns2_ip}\n"
        
        report += f"""  ✅ MX record: {self.domain} → mail.{self.domain}
  ✅ TXT record: SPF
  ✅ TXT record: DMARC
  ✅ CNAME records: ftp, webmail, cpanel, whm

TESTING COMMANDS:
  dig {self.domain}
  dig NS {self.domain}
  dig @{self.ns1_ip} {self.domain}
  nslookup {self.domain} {self.ns1_ip}

{'='*60}
"""
        
        return report


def main():
    """Main execution"""
    
    if len(sys.argv) < 4:
        print("""
Usage: dns-automation.py <domain> <server_ip> <ns1_ip> [ns2_ip]

Example:
  dns-automation.py example.com 54.23.45.67 52.10.20.30 52.10.20.31

Arguments:
  domain     - Customer domain name
  server_ip  - IP address of the hosting server
  ns1_ip     - IP address of primary DNS server (Bind9)
  ns2_ip     - IP address of secondary DNS server (optional)
""")
        sys.exit(1)
    
    domain = sys.argv[1]
    server_ip = sys.argv[2]
    ns1_ip = sys.argv[3]
    ns2_ip = sys.argv[4] if len(sys.argv) > 4 else None
    
    print(f"""
{'='*60}
NEO VPS DNS AUTOMATION
{'='*60}
Domain: {domain}
Server: {server_ip}
NS1: {ns1_ip}
NS2: {ns2_ip or 'None'}
{'='*60}
""")
    
    try:
        # Initialize automation
        dns = DNSAutomation(domain, server_ip, ns1_ip, ns2_ip)
        
        # Step 1: Create hosted zone
        zone_id, nameservers = dns.create_hosted_zone()
        
        # Step 2: Create DNS records
        change_id = dns.create_dns_records()
        
        # Step 3: Test nameservers
        ns_results = dns.test_nameservers()
        
        # Step 4: Verify propagation
        dns.verify_dns_propagation(max_retries=3, delay=10)
        
        # Step 5: Save to DynamoDB
        dns.save_to_dynamodb()
        
        # Step 6: Generate report
        report = dns.generate_report()
        print(report)
        
        # Save report to file
        report_file = f"/tmp/dns-report-{domain}-{datetime.now().strftime('%Y%m%d-%H%M%S')}.txt"
        with open(report_file, 'w') as f:
            f.write(report)
        
        print(f"📄 Report saved to: {report_file}")
        
        print(f"""
{'='*60}
✅ DNS AUTOMATION COMPLETED SUCCESSFULLY
{'='*60}

Next steps:
1. Update nameservers at domain registrar
2. Wait 24-48 hours for propagation
3. Test with: dig NS {domain}

{'='*60}
""")
        
        sys.exit(0)
        
    except KeyboardInterrupt:
        print("\n⚠️  Operation cancelled by user")
        sys.exit(130)
        
    except Exception as e:
        print(f"\n❌ DNS automation failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
