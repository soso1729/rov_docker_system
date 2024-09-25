#!/bin/bash  

IMAGE_VER="noetic"
IMAGE_NAME="ros:noetic"
CONTAINER_NAME="rov_ros_noetic"  
HOST_NAME="rov_noetic_cui"
GUI_MODE=false
GIT_URL="https://github.com/soso1729/rov_docker_system.git"

NOETIC_WORK_DIR="$HOME/rov_docker_system/ros_noetic_ws"
HUMBLE_WORK_DIR="$HOME/rov_docker_system/ros_humble_ws"
WORK_DIR="$NOETIC_WORK_DIR"  

sudo apt update && sudo apt upgrade -y

git pull origin main

if ! command -v docker &> /dev/null; then
    sudo apt-get remove docker docker-engine docker.io containerd runc -y
    sudo apt-get update
    sudo apt-get install \
        ca-certificates \
        curl \
        gnupg \
        lsb-release -y
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    sudo systemctl start docker
    sudo systemctl enable docker
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --GUI)
            GUI_MODE=true
            CONTAINER_NAME="rov_ros_${IMAGE_VER}_gui"
            HOST_NAME="rov_${IMAGE_VER}_gui"
            shift
            ;;
        --CUI)
            if [[ "$IMAGE_VER" != "humble" ]]; then
                GUI_MODE=false
                CONTAINER_NAME="rov_ros_${IMAGE_VER}_cui"
                HOST_NAME="rov_${IMAGE_VER}_cui"
            else
                echo "Warning: --humble only supports GUI mode. Ignoring --CUI."
            fi
            shift
            ;;
        --humble)    
            GUI_MODE=true
            IMAGE_VER="humble"
            IMAGE_NAME="ros:humble"
            CONTAINER_NAME="rov_ros_${IMAGE_VER}_gui"
            HOST_NAME="rov_${IMAGE_VER}_gui"
            WORK_DIR="$HUMBLE_WORK_DIR" 
            shift
            ;;
        -w|--workspace)
            WORK_DIR="$2"
            shift
            shift
            ;;
        -I|--image)
            IMAGE_NAME="$2"
            shift
            shift
            ;;
        -N|--name)
            CONTAINER_NAME="$2"
            shift
            shift
            ;;
        *)
            POSITIONAL_ARGS+=("$1") 
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

if [ ! -d "$WORK_DIR" ]; then
    echo "Creating ROS workspace directory at $WORK_DIR"
    mkdir -p "$WORK_DIR/src"
fi

container_exists=$(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}')

docker pull "$IMAGE_NAME"

if [ "$IMAGE_VER" == "humble" ]; then
    if [ "$container_exists" == "$CONTAINER_NAME" ]; then
        xhost +local:docker
        echo "Container $CONTAINER_NAME already exists. Starting it..."
        docker start -ai "$CONTAINER_NAME"
    else
        echo "Creating a new container $CONTAINER_NAME (ROS 2 Humble)..."

        cd "$WORK_DIR/src"
        git clone https://github.com/tasada038/ping_sonar_ros.git 

        if [ ! -d "/tmp/.X11-unix" ]; then
            echo "/tmp/.X11-unix does not exist. Ensure X server is running."
            exit 1
        fi
        
        echo "Starting Docker container with GUI support (ROS 2 Humble)..."
        
        xhost +local:docker
        if [ $? -ne 0 ]; then
            echo "Failed to set X11 permissions with xhost. Ensure X server is running and accessible."
            exit 1
        fi

        docker run -it \
            --name="${CONTAINER_NAME}" \
            --hostname="$HOST_NAME" \
            --env="DISPLAY=$DISPLAY" \
            --env="QT_X11_NO_MITSHM=1" \
            --env="LIBGL_ALWAYS_SOFTWARE=1" \
            --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
            --volume="${HOME}/rov_docker_system/ros_noetic_ws:/root/userdir" \
            --device="/dev/input:/dev/input:rw" \
            $IMAGE_NAME bash -c "
            
            source /opt/ros/humble/setup.bash

            if [ ! -f /root/userdir/install/setup.bash ]; then
                echo 'Setting up ROS 2 Humble workspace...'
                cd /root/userdir
                mkdir -p src
                colcon build
                source install/setup.bash
            else
                echo 'ROS 2 Humble workspace already exists. Sourcing workspace...'
                source /root/userdir/install/setup.bash
            fi

            apt update && apt install -y \
            ros-humble-rviz2 \
            ros-humble-gazebo-ros-pkgs \
            ros-humble-teleop-twist-keyboard \
            ros-humble-joy

            bash
            "
        xhost -local:docker
    fi

else
    if [ "$container_exists" == "$CONTAINER_NAME" ]; then
        xhost +local:docker
        echo "Container $CONTAINER_NAME already exists. Starting it..."
        docker start -ai "$CONTAINER_NAME"
    else
        echo "Creating a new container $CONTAINER_NAME..."

        ## コンテナ作成(GUI運用)
        if [ "$GUI_MODE" = true ]; then

            cd "$WORK_DIR/src"
            git clone https://github.com/fredvaz/bluerov2.git
            git clone https://github.com/arturmiller/uuv_simulator.git

            if [ ! -d "/tmp/.X11-unix" ]; then
                echo "/tmp/.X11-unix does not exist. Ensure X server is running."
                exit 1
            fi
            
            echo "Starting Docker container with GUI support (ROS Noetic)..."
            
            xhost +local:docker
            if [ $? -ne 0 ]; then
                echo "Failed to set X11 permissions with xhost. Ensure X server is running and accessible."
                exit 1
            fi
            
            docker run -it \
                --name="${CONTAINER_NAME}" \
                --hostname="$HOST_NAME" \
                --env="DISPLAY=$DISPLAY" \
                --env="QT_X11_NO_MITSHM=1" \
                --env="LIBGL_ALWAYS_SOFTWARE=1" \
                --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
                --volume="$HOME/rov_docker_system/ros_noetic_ws:/root/userdir" \
                --device="/dev/input:/dev/input:rw" \
                $IMAGE_NAME bash -c "
                roscore &

                apt update && apt install -y libgl1-mesa-glx libgl1-mesa-dri

                source /opt/ros/noetic/setup.bash

                if [ ! -f /root/userdir/devel/setup.bash ]; then
                    echo 'Setting up ROS workspace...'
                    cd /root/userdir
                    catkin_make
                    source devel/setup.bash
                else
                    echo 'ROS workspace already exists. Sourcing workspace...'
                    source /root/userdir/devel/setup.bash
                fi

                echo 'keyboard-configuration keyboard-configuration/layoutcode string jp' | debconf-set-selections &&
                echo 'keyboard-configuration keyboard-configuration/modelcode string pc105' | debconf-set-selections &&
                echo 'keyboard-configuration keyboard-configuration/xkb-keymap select jp' | debconf-set-selections &&

                apt update && apt install -y \
                ros-noetic-gazebo-ros \
                ros-noetic-gazebo-plugins \
                ros-noetic-move-base \
                ros-noetic-amcl \
                ros-noetic-map-server \
                ros-noetic-teb-local-planner \
                ros-noetic-dwa-local-planner \
                ros-noetic-global-planner \
                ros-noetic-rviz \
                ros-noetic-rqt \
                ros-noetic-rqt-common-plugins \
                ros-noetic-xacro \
                ros-noetic-joy

                if [ -L /tmp/rov_move ]; then
                    echo 'Existing symbolic link /tmp/rov_move found. Removing it.'
                    rm -f /tmp/rov_move
                elif [ -d /tmp/rov_move ]; then
                    echo 'Existing directory /tmp/rov_move found. Removing it.'
                    rm -rf /tmp/rov_move
                fi

                ln -s ~/userdir/rov_move /tmp/rov_move

                cd ~/userdir
                catkin_make

                bash
                "
            xhost -local:docker
        
        ## コンテナ作成 (CUI運用)
        else 

            cd "$WORK_DIR/src"
            git clone https://github.com/fredvaz/bluerov2.git
            git clone https://github.com/arturmiller/uuv_simulator.git

            echo "Starting Docker container in CUI mode (ROS Noetic)..."
            docker run -it \
                --name="${CONTAINER_NAME}" \
                --hostname="$HOST_NAME" \
                --volume="$HOME/rov_docker_system/ros_noetic_ws:/root/userdir" \
                --env="LIBGL_ALWAYS_SOFTWARE=1" \
                --device="/dev/input:/dev/input:rw" \
                $IMAGE_NAME bash -c "
                apt update && apt install -y libgl1-mesa-glx libgl1-mesa-dri

                source /opt/ros/noetic/setup.bash

                roscore &
                
                if [ ! -f /root/userdir/devel/setup.bash ]; then
                    echo 'Setting up ROS workspace...'
                    cd /root/userdir
                    catkin_make
                    source devel/setup.bash
                else
                    echo 'ROS workspace already exists. Sourcing workspace...'
                    source /root/userdir/devel/setup.bash
                fi

                echo 'keyboard-configuration keyboard-configuration/layoutcode string jp' | debconf-set-selections &&
                echo 'keyboard-configuration keyboard-configuration/modelcode string pc105' | debconf-set-selections &&
                echo 'keyboard-configuration keyboard-configuration/xkb-keymap select jp' | debconf-set-selections &&

                apt update && apt install -y \
                ros-noetic-gazebo-ros \
                ros-noetic-gazebo-plugins \
                ros-noetic-move-base \
                ros-noetic-amcl \
                ros-noetic-map-server \
                ros-noetic-teb-local-planner \
                ros-noetic-dwa-local-planner \
                ros-noetic-global-planner \
                ros-noetic-rviz \
                ros-noetic-rqt \
                ros-noetic-rqt-common-plugins \
                ros-noetic-xacro \
                ros-noetic-joy

                if [ -L /tmp/rov_move ]; then
                    echo 'Existing symbolic link /tmp/rov_move found. Removing it.'
                    rm -f /tmp/rov_move
                elif [ -d /tmp/rov_move ]; then
                    echo 'Existing directory /tmp/rov_move found. Removing it.'
                    rm -rf /tmp/rov_move
                fi

                ln -s ~/userdir/rov_move /tmp/rov_move

                cd ~/userdir
                catkin_make

                bash
                "
        fi
    fi
fi
