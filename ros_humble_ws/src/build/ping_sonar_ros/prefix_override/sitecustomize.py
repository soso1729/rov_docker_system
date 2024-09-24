import sys
if sys.prefix == '/usr':
    sys.real_prefix = sys.prefix
    sys.prefix = sys.exec_prefix = '/home/satou5473/rov_docker_system/ros_humble_ws/src/install/ping_sonar_ros'
