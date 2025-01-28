#!/bin/bash

# Function to find and kill the process
kill_process() {
    local process_path="/home/hello-robot/smart-home/install/shr_plan/lib/shr_plan/planning_controller_node"
    local pid=$(pidof -x "$(basename "$process_path")")
    if [ -n "$pid" ]; then
        echo "Killing process with PID $pid"
        kill -9 $pid
        sleep 30s
    else
        echo "Process not found"
    fi
}

# Function to start the process
start_process() {
    echo "Starting process..."
    /usr/bin/python3 /opt/ros/humble/bin/ros2 run shr_plan planning_controller_node > /tmp/planner.txt 2>&1 &  # redirects the output of starting 
    sleep 30s
}

#function to check if process is running, start if not, and restart daily
check_and_restart_daily() {
    while true; do
        now=$(date +%H:%M)
        echo "$now."
        if [ "$now" == "00:00" ]; then
        ## commented becasue we are now using the script
            echo "Process is going to be restarted."
            #kill_process
            sleep 1m
            #start_process
            echo "Process is restarted."
            echo "Sleeping for 10 mins."
            #sleep 10m  # Wait for 10 mins before checking again
        else
            local process_path="/home/hello-robot/smart-home/install/shr_plan/lib/shr_plan/planning_controller_node"
            local pid=$(pidof -x "$(basename "$process_path")")
            if [ -n "$pid" ]; then
                echo "PID of $process_path is $pid"
                if [ $(( $(date +%M) % 10 )) -eq 0 ]; then
                    echo "Sleep for 10 minutes."
                    sleep 10m
                else
                    echo "Sleep for 1 minute."
                    sleep 1m
                fi
            else
                echo "Process $process_path is not running. Starting it..."
                start_process
                echo "Started process with PID $pid"
                sleep 5m
            fi
        fi
    done
}

# Main function
main() {
    check_and_restart_daily
}

# Execute the main function
main
