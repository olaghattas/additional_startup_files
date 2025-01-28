#!/bin/bash

## make sure when added to the startup script it should start after min 10 mins or whatever time is used so that after restrat it doesnt retsrat again
# JSON file path
json_file="/home/hello-robot/protocol_time.json"

if [ ! -f "$json_file" ]; then
    echo "File $json_file not found."
    exit 1
fi

# Function to check if a string exists in the file
check_string_in_file() {
    local string_to_check=$1
    local file_path="/home/hello-robot/planner_data/plan_solver/problem.pddl"
    # Check if the string exists in the file
    if [ -f "$file_path" ]; then
        if grep -q "$string_to_check" "$file_path"; then
            echo "String '$string_to_check' found in $file_path."
            return 1
        else
            echo "String '$string_to_check' not found in $file_path."
            return 0
        fi
    fi
}


# Function to check if a time is within a time window
time_within_window() {
    local start_minutes=$1
    local end_minutes=$2
    local current_minutes=$3

    # echo "IN WINDOW FUNCTION"
    echo $start_minutes
    echo $end_minutes
    echo $current_minutes

    if (( current_minutes >= start_minutes && current_minutes <= end_minutes )); then
        echo "YES"
        return 1
    else
        echo "No"
        return 0
    fi
}


# Function to check if current time is 10 minutes before the start time of a window
is_10_minutes_before_window_start() {
    local start_time_minutes=$1
    local current_time_minutes=$2
  
    # Calculate time 10 minutes before start time
    ten_minutes_before=$((start_time_minutes - 10))

    if ((current_time_minutes >= ten_minutes_before && current_time_minutes < start_time_minutes)); then
        # echo "Yes"
        return 1
    else
        # echo "no"
        return 0
    fi
    
}

run_ros_kill() {
# Run my_script.sh
python3 /home/hello-robot/kill_ros.py
}

stopped=0
# Main loop to keep checking every 2 minutes
while true; do
    # Get current time
    current_time=$(date +"%H:%M")
    echo "current_time" "$current_time"
    # Convert start and end times to minutes past midnight
    current_minutes=$(date -d "$current_time" +"%H*60+%M" | bc)
    echo "current_minutes" "$current_minutes" 

    # Read JSON file and check time windows
    time_windows=$(jq -r '.time_windows[] | @base64' "$json_file")
    for tw_base64 in $time_windows; do
        tw=$(echo "$tw_base64" | base64 --decode)
        start_time=$(jq -r '.start_time' <<< "$tw")
        start_minutes=$(date -d "$start_time" +"%H*60+%M" | bc)

        echo "FIRST check if 10 mins before window"

        echo "start_time" "$start_minutes"    
        # Check if current time is 10 minutes before start time
        is_10_minutes_before_window_start $start_minutes $current_minutes
        ten_mins=$?
        echo "ten_mins status: $ten_mins"
        echo "stopped" "$stopped"
        #if [ "$ten_mins" -eq 1 ] && [ $stopped -eq 1 ]; then
        if [ "$ten_mins" -eq 1 ]; then
            echo "time 10 minutes before"
            # Your password (replace 'your_password' with the actual password)
            password="hello2020"

            # Use echo to pass the password to sudo
            echo "$password" | sudo -S reboot

        fi

        end_time=$(jq -r '.end_time' <<< "$tw")
        end_minutes=$(date -d "$end_time" +"%H*60+%M" | bc)

    	IFS=$'\n' read -r -d '' -a strings <<< "$(jq -r '.strings[] | @sh' <<< "$tw")"
        echo "Processed Strings: ${strings[@]}"
        # check if current time is between window 
        echo "SECOND check if time within window"

        time_within_window $start_minutes $end_minutes $current_minutes
        return_status=$?
        # Print the return status
        echo "Return status: $return_status"

        if [ $return_status -eq 1 ] && [ $stopped -eq 0 ]; then
            echo "Within time window ($start_time - $end_time):"
            echo "stopped: " "$stopped"
            while true; do
                echo "THIRD check for string"
                # Check every 5 minutes if the file name includes the strings corresponding to the time window
                echo "${strings[@]}"
                for string_to_check in "${strings[@]}"; do
                    # Remove quotations from the string being checked
        	    string_to_check=$(echo "$string_to_check" | sed "s/'//g")
                    echo "Checking for string: $string_to_check"
                    # Perform check for string in file
                    check_string_in_file "$string_to_check"
                    string_in_file=$?
                    echo "&&&&& string_in_file" "$string_in_file"
                    
                    # Check if string is found in file
                    if [ $string_in_file -eq 1 ]; then
                    	echo "check if robot charging"
                        while IFS= read -r line; do
			    echo "line: " "$line"
			    if [[ $line == "data: 1" ]]; then
				echo "data: 1 found, breaking out of the loop"
				break
			    fi
			done < <(ros2 topic echo /charging)
                        run_ros_kill
                        stopped=1
                        # break from for loop
                        break
                    fi
                done
                
                if [ $stopped -eq 1 ]; then
                # break from while loop
                    echo "stopped2: " "$stopped"
                    break
                fi
                 
                # Wait for 5 minutes before checking again
                sleep  300
                ## to prevent infinite loop
                current_time=$(date +"%H:%M")
                echo "current_time" "$current_time"
                # Convert start and end times to minutes past midnight
                current_minutes=$(date -d "$current_time" +"%H*60+%M" | bc)
                time_within_window $start_minutes $end_minutes $current_minutes
                return_status_loop=$?
                echo "NOT Within time window ($start_time - $end_time):"
                if [ $return_status_loop -eq 0 ]; then
                    echo "Stop in infinite loop ($start_time - $end_time):"
                    run_ros_kill
                    stopped=1
                    break 
                fi
                
            done
        else
            if [ $stopped -eq 1 ]; then
            	echo "Already stopped ($start_time - $end_time):"
            else
            	echo "NOT Within time window ($start_time - $end_time):"
            fi
        fi
    done
  
    # Wait for 2 minutes before checking again
    echo "SLEPPING FOR 2 MINS"
    sleep 120
done


