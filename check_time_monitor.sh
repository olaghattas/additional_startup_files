#!/bin/bash

# Function to start the process
start_process() {
    echo "Starting process..."
    /home/hello-robot/check_time_date.sh > /home/hello-robot/check_time_date.txt 2>&1 &  # redirects the output of starting 
    sleep 30s
}

#function to check if process is running, start if not, and restart daily
check_time() {
    while true; do
            local process_path="/bin/bash /home/hello-robot/check_time_date.sh"
            local pid=$(pidof -x "$(basename "$process_path")")
            if [ -n "$pid" ]; then
                echo "PID of $process_path is $pid"
                echo "Sleep for 10 minutes."
                sleep 10m    
            else
                echo "Process $process_path is not running. Starting it..."
                start_process
                echo "Started process with PID $pid"
                sleep 10m
            fi
        
    done
}

# Main function
main() {
    check_time
}

# Execute the main function
main
