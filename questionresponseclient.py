import rclpy
from rclpy.node import Node
from action_msgs.msg import GoalStatus
from convros_interfaces.action import QuestionResponseRequest
from rclpy.action import ActionClient
from rclpy.executors import SingleThreadedExecutor
import subprocess


class QuestionResponseClient(Node):

    def __init__(self):
        super().__init__('question_response_client')
        # Create an action client
        self._action_client = ActionClient(self, QuestionResponseRequest, 'question_response_action')
        self._goal_handle = None
        self.script_path = '/home/hello-robot/sh_startup_not_onboot.sh'


    def send_goal(self):
        # Create a goal request
        goal_msg = QuestionResponseRequest.Goal()
        goal_msg.question = "Do you want me to show how to operate the Microwave oven?"

        # Send the goal asynchronously
        self._action_client.wait_for_server()
        self.get_logger().info('Sending goal...')
        send_goal_future = self._action_client.send_goal_async(goal_msg, self.feedback_callback)
        send_goal_future.add_done_callback(self.goal_response_callback)

    def goal_response_callback(self, future):
        goal_handle = future.result()
        if not goal_handle.accepted:
            self.get_logger().info('Goal rejected.')
            return

        self.get_logger().info('Goal accepted. Waiting for result...')
        self._goal_handle = goal_handle
        result_future = self._goal_handle.get_result_async()
        result_future.add_done_callback(self.result_callback)
        print("goal respone done")

    def feedback_callback(self, feedback_msg):
        # self.get_logger().info(f'Feedback received: {feedback_msg.feedback}')
        pass

    def result_callback(self, future):
        result = future.result().result
        # self.get_logger().info(f'Result: {result}')
        # print("result:  ",type(result.response))
        # print("sdlkjfhlkjsd ",result.response == "yes")
        # Use subprocess.run to execute the shell script

        try:
            result_ = subprocess.run(['bash', script_path], check=True, text=True, capture_output=True)
            print("Script executed successfully:")
            print(result.stdout)  # Output of the script
        except subprocess.CalledProcessError as e:
            print(f"Error occurred while running the script: {e}")
            print(e.stderr)  # Error output from the script



def main(args=None):
    rclpy.init(args=args)

    question_response_client = QuestionResponseClient()
    question_response_client.send_goal()

    executor = SingleThreadedExecutor()
    executor.add_node(question_response_client)

    try:
        executor.spin()
    except KeyboardInterrupt:
        pass
    finally:
        question_response_client.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
