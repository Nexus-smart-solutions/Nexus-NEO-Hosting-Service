import boto3
import json

cloudwatch = boto3.client('cloudwatch')

def create_customer_dashboard(domain, instance_id):
    """Create CloudWatch dashboard for customer"""
    
    dashboard_name = f"neo-vps-{domain.replace('.', '-')}"
    
    dashboard_body = {
        "widgets": [
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/EC2", "CPUUtilization", {"stat": "Average", "label": "CPU"}],
                    ],
                    "view": "timeSeries",
                    "region": "us-east-1",
                    "title": "CPU Utilization",
                    "period": 300,
                    "yAxis": {"left": {"min": 0, "max": 100}}
                }
            },
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["NeoVPS", "DISK_USED", {"stat": "Average"}],
                        [".", "MEM_USED", {"stat": "Average"}]
                    ],
                    "view": "timeSeries",
                    "region": "us-east-1",
                    "title": "Disk & Memory Usage",
                    "period": 300
                }
            }
        ]
    }
    
    cloudwatch.put_dashboard(
        DashboardName=dashboard_name,
        DashboardBody=json.dumps(dashboard_body)
    )
    
    print(f"✅ Created dashboard: {dashboard_name}")
    print(f"🔗 https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name={dashboard_name}")

if __name__ == '__main__':
    import sys
    create_customer_dashboard(sys.argv[1], sys.argv[2])