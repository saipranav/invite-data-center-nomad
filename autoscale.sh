# Autoscales a service with respect to Cpu usage of that service; Note: Runs with only consul and nomad
# Assumptions:
# 1) .nomad job files should be in /opt/nomad/jobs folder
# 2) .nomad files should have service group first then load balancer for that service
# Author : Sai Pranav (rsaipranav92@gmail.com)
# Licence : GPLv3

highCpuThreshold=60
lowCpuThreshold=5
minInstancesForANode=1
sleep=$( shuf -i 40-65 -n 1)

command=node
# Changing the command to [c]ommand format so that ps , grep wont reply with grep as a process
command=$( echo '['${command:0:1}']'${command:1} )

# Service name from process TODO have a list of services
service=person

# Checks the Cpu usage with pid of service and takes decision
function checkAndScale() {
	# Grab the process ids for the given command
	local pids=$( ps -eo pid,args | grep $command | awk '{print $1}' )

	# if no process running return the exec flow 
	if [ -z "$pids" ]
	then
		return
	fi

	# Get top output for the pids and sort be CPU and get the highest CPU usage
	local pids=$( echo $pids | sed 's/ /,/g' )

	local highCpu=$( top -b -n 1 -p $pids -o %CPU | head -8 | tail -1 | awk '{print $9}' )
	# highCpu=62.8 # Just for testing
	# Convert the float to integer
	highCpu=$( echo "($highCpu+0.5)/1" | bc )
	
	# Grab the command for increasing the instance
	local highPid=$( top -b -n 1 -p $pids -o %CPU | head -8 | tail -1 | awk '{print $1}' )
	local highCommand=$( ps -p $highPid -o args | tail -1 )

	# Number of instances of highest command in whole cluster
	local numberOfInstances=$( curl -s http://localhost:8500/v1/health/service/$service | grep -o '{"Node":{' | wc -l )
	echo "Command : $highCommand | Cpu Util : $highCpu | Instances : $numberOfInstances"

	# High Threshold - 60 && Low Threshold - 10 
	if [ $highCpu -gt $highCpuThreshold ]
	then
		local existingCount=$( cat /opt/nomad/jobs/$service.nomad | grep 'count = ' | head -1 | awk '{print $3}' )
		echo "Already existing number of instances $existingCount; Increasing by 1"
		local newCount=$((existingCount+1))
		sed -i '0,/count = '$existingCount'/s/count = '$existingCount'/count = '$newCount'/' /opt/nomad/jobs/$service.nomad
		nomad run /opt/nomad/jobs/$service.nomad
	elif [ $highCpu -lt $lowCpuThreshold ]
	then
		if [ $numberOfInstances -gt $minInstancesForANode ]
		then
			local existingCount=$( cat /opt/nomad/jobs/$service.nomad | grep 'count = ' | head -1 | awk '{print $3}' )
			echo "Already existing number of instances $existingCount; Decreasing by 1"
			local newCount=$((existingCount-1))
			sed -i '0,/count = '$existingCount'/s/count = '$existingCount'/count = '$newCount'/' /opt/nomad/jobs/$service.nomad
			nomad run /opt/nomad/jobs/$service.nomad
		else
			echo "Only one instance so leave it"
		fi
	else
		echo "System is stable in handling traffic"
	fi
}

# Sync the counts for .nomad files in all nodes
function syncCounts(){
	# Gets current instances of a service from consul
	local numberOfInstances=$( curl -s http://localhost:8500/v1/health/service/$service | grep -o '{"Node":{' | wc -l )

	# Get the count in .nomad file of a service
	local existingCount=$( cat /opt/nomad/jobs/$service.nomad | grep 'count = ' | head -1 | awk '{print $3}' )

	# check for any difference if so replace the count in .nomad file with number of instances from consul
	if [ $numberOfInstances -ne $existingCount ]
	then
		if [ $numberOfInstances -eq 0 ]
		then
			numberOfInstances=1
		fi
		sed -i '0,/count = '$existingCount'/s/count = '$existingCount'/count = '$numberOfInstances'/' /opt/nomad/jobs/$service.nomad
	fi
}

# infinite loop that executes autoscaler for every 5 seconds
while true
do
	checkAndScale
	syncCounts
	sleep $sleep
done
