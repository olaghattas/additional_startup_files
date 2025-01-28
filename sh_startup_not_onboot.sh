#!/bin/bash


ros2 launch stretch_nav2 navigation.launch.py map:=/home/hello-robot/stretch_user/maps/map.yaml > /tmp/navigation.txt 2>&1 &
sleep 30s
echo "nav2 processes..."

ros2 launch realsense2_camera rs_launch.py &
sleep 30s

ros2 service call /runstop std_srvs/srv/SetBool data:\ false\ &
##sleep 30s

ros2 launch shr_plan real_robot.launch.py > /tmp/real_robot.txt 2>&1 &
sleep 30s

ros2 launch shr_plan action_servers.launch.py > /tmp/action_server.txt 2>&1 &
sleep 30s

ros2 run shr_plan planning_controller_node > /tmp/planner.txt 2>&1 &

sleep 20s #2 minute sleep
ros2 run simple_logger simple_logger_web > /tmp/logger.txt 2>&1 &

#sleep 5s
#/home/hello-robot/planner_monitor.sh > /home/hello-robot/planner_monitor.txt 2>&1 &


#sleep 600s
##/home/hello-robot/check_time_date.sh > /home/hello-robot/check_time_date.txt 2>&1 &

#sleep 300s
#/home/hello-robot/check_time_monitor.sh > /home/hello-robot/check_time_monitor.txt 2>&1 &


wait
