#!/bin/sh
# This script will monitor another NAT instance and take over its routes
# if communication with the other instance fails

# NAT instance variables
# Other instance's IP to ping and route to grab if other node goes down
NAT_ID=
NAT_RT_ID=

# My route to grab when I come back up
My_RT_ID=

# Specify the EC2 region that this will be running in (e.g. https://ec2.us-east-1.amazonaws.com)
EC2_URL=

# Health Check variables
Num_Pings=3
Ping_Timeout=1
Wait_Between_Pings=2
Wait_for_Instance_Stop=60
Wait_for_Instance_Start=300

# Run aws-apitools-common.sh to set up default environment variables and to
# leverage AWS security credentials provided by EC2 roles
. /etc/profile.d/aws-apitools-common.sh

# Determine the NAT instance private IP so we can ping the other NAT instance, take over
# its route, and reboot it.  Requires EC2 DescribeInstances, ReplaceRoute, and Start/RebootInstances
# permissions.  The following example EC2 Roles policy will authorize these commands:
# {
#  "Statement": [
#    {
#      "Action": [
#        "ec2:DescribeInstances",
#        "ec2:CreateRoute",
#        "ec2:ReplaceRoute",
#        "ec2:StartInstances",
#        "ec2:StopInstances"
#      ],
#      "Effect": "Allow",
#      "Resource": "*"
#    }
#  ]
# }

# Get this instance's ID
Instance_ID=`/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/instance-id`
# Get the other NAT instance's IP
NAT_IP=`/opt/aws/bin/ec2-describe-instances $NAT_ID -U $EC2_URL | grep PRIVATEIPADDRESS -m 1 | awk '{print $2;}'`

echo `date` "-- Starting NAT monitor"
echo `date` "-- Adding this instance, $Instance_ID, to $My_RT_ID default route on start"
echo `date` "-- Monitor the other NAT, $NAT_IP."
echo `date` "-- " `/opt/aws/bin/ec2-replace-route $My_RT_ID -r 0.0.0.0/0 -i $Instance_ID -U $EC2_URL`
# If replace-route failed, then the route might not exist and may need to be created instead
if [ "$?" != "0" ]; then
echo `date` "-- " `/opt/aws/bin/ec2-create-route $My_RT_ID -r 0.0.0.0/0 -i $Instance_ID -U $EC2_URL`
fi

while [ . ]; do
  # Check health of other NAT instance
  pingresult=`ping -c $Num_Pings -W $Ping_Timeout $NAT_IP | grep time= | wc -l`
  # Check to see if any of the health checks succeeded, if not
  if [ "$pingresult" == "0" ]; then
    # Set HEALTHY variables to unhealthy (0)
    ROUTE_HEALTHY=0
    NAT_HEALTHY=0
    STOPPING_NAT=0
    while [ "$NAT_HEALTHY" == "0" ]; do
      # NAT instance is unhealthy, loop while we try to fix it
      if [ "$ROUTE_HEALTHY" == "0" ]; then
    	echo `date` "-- Other NAT heartbeat failed, $NAT_IP, taking over $NAT_RT_ID default route"
    	echo `date` "-- " `/opt/aws/bin/ec2-replace-route $NAT_RT_ID -r 0.0.0.0/0 -i $Instance_ID -U $EC2_URL`
	    ROUTE_HEALTHY=1
      fi
      # Check NAT state to see if we should stop it or start it again
	  # This sample script works well with EC2 API tools version 1.6.12.2 2013-10-15. If you are using a different version and your script is stuck at NAT_STATE, please modify the script to "print $5;" instead of "print $4;".
      NAT_STATE=`/opt/aws/bin/ec2-describe-instances $NAT_ID -U $EC2_URL | grep INSTANCE | awk '{print $6;}'`
      echo `date` "-- the other NAT, $NAT_IP, STATE=$NAT_STATE"
      if [ "$NAT_STATE" == "stopped" ]; then
    	echo `date` "-- Other NAT instance, $NAT_IP, stopped, starting it back up"
        echo `date` "-- " `/opt/aws/bin/ec2-start-instances $NAT_ID -U $EC2_URL`
	    NAT_HEALTHY=1
        sleep $Wait_for_Instance_Start
      #disable this to prevent rebooting circle problem
      #else
      #  if [ "$STOPPING_NAT" == "0" ]; then
      #    echo `date` "-- Other NAT instance, $NAT_IP, $NAT_STATE, attempting to stop for reboot"
      #    echo `date` "-- " `/opt/aws/bin/ec2-stop-instances $NAT_ID -U $EC2_URL`
      #    STOPPING_NAT=1
      #  fi
      #  sleep $Wait_for_Instance_Stop
      fi
    done
  else
    sleep $Wait_Between_Pings
  fi
done
