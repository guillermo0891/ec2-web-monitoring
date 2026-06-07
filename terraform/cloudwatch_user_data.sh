#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y wget unzip collectd
AGENT_DEB="/tmp/amazon-cloudwatch-agent.deb"
wget -O ${AGENT_DEB} https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i ${AGENT_DEB} || true
touch /var/log/dmesg
nohup bash -c "dmesg -w > /var/log/dmesg" >/dev/null 2>&1 &
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<'EOF'
{
  "agent": { "metrics_collection_interval": 60, "run_as_user": "root" },
  "metrics": {
    "namespace": "Custom/EC2",
    "metrics_collected": {
      "cpu": { "measurement": ["cpu_usage_active","cpu_usage_idle"], "metrics_collection_interval": 60 },
      "mem": { "measurement": ["mem_used_percent"], "metrics_collection_interval": 60 },
      "disk": { "measurement": ["disk_used_percent"], "metrics_collection_interval": 60, "resources": ["/"] }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/syslog", "log_group_name": "/ec2/syslog", "timestamp_format": "%b %d %H:%M:%S" },
          { "file_path": "/var/log/dmesg",  "log_group_name": "/ec2/dmesg",  "timestamp_format": "%b %d %H:%M:%S" }
        ]
      }
    }
  }
}
EOF
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s || true