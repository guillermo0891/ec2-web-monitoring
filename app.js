const express = require('express');
const AWS = require('aws-sdk');
const app = express();
const region = process.env.AWS_REGION || 'us-east-1';
AWS.config.update({ region });
const cw = new AWS.CloudWatch();
const logs = new AWS.CloudWatchLogs();

app.get('/', (req,res) => res.send('Monitoring web app running'));

app.get('/metrics/:instanceId/:metric', async (req, res) => {
  const { instanceId, metric } = req.params;
  const now = new Date();
  const start = new Date(now.getTime() - 5*60*1000);
  const metricNameMap = {
    cpu: 'cpu_usage_active',
    mem: 'mem_used_percent',
    disk: 'disk_used_percent'
  };
  const metricName = metricNameMap[metric] || metric;
  const params = {
    StartTime: start,
    EndTime: now,
    MetricDataQueries: [{
      Id: 'm1',
      MetricStat: {
        Metric: {
          Namespace: 'Custom/EC2',
          MetricName: metricName,
          Dimensions: [{ Name: 'InstanceId', Value: instanceId }]
        },
        Period: 60,
        Stat: 'Average'
      },
      ReturnData: true
    }]
  };
  try {
    const data = await cw.getMetricData(params).promise();
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/logs/dmesg', async (req, res) => {
  try {
    const data = await logs.filterLogEvents({
      logGroupName: '/ec2/dmesg',
      limit: 100,
      interleaved: true
    }).promise();
    res.json(data.events || []);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, ()=> console.log('Listening', port));