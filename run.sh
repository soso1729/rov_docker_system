#!/bin/bash  

WORK_DIR="$(pwd)/userdir"
IMAGE_NAME="ros:noetic"
CONTAINER_NAME="rov_ros_noetic"  
HOST_NAME="rov_noetic"
GUI_MODE=false
GIT_URL="https://github.com/soso1729/rov_docker_system.git"

sudo apt update
git pull origin main

while [[ $# -gt 0 ]]; do
    case $1 in
        --GUI)
            GUI_MODE=true
            CONTAINER_NAME="rov_ros_noetic_gui"
            HOST_NAME="rov_noetic_gui"
            shift
            ;;
        --CUI)
            GUI_MODE=false
            CONTAINER_NAME="rov_ros_noetic_cui"
            HOST_NAME="rov_noetic_cui"
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
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

if [ ! -d "$WORK_DIR" ]; then
    echo "Creating ROS workspace directory at $WORK_DIR"
    mkdir -p "$WORK_DIR/src"
fi

container_exists=$(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}')

if [ "$container_exists" == "$CONTAINER_NAME" ]; then
    echo "Container $CONTAINER_NAME already exists. Starting it..."
    docker start -ai "$CONTAINER_NAME"
else
    echo "Creating a new container $CONTAINER_NAME..."

##コンテナ作成(GUI運用)
    if [ "$GUI_MODE" = true ]; then
        echo "Starting Docker container with GUI support (ROS Noetic)..."
        xhost +local:docker  
        docker run -it \
            --name="${CONTAINER_NAME}" \
            --hostname="$HOST_NAME" \
            --env="DISPLAY" \
            --env="QT_X11_NO_MITSHM=1" \
            --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
            --volume="$WORK_DIR:/root/userdir" \
            $IMAGE_NAME bash -c "

            # ROS Desktop Fullがインストールされていない場合にインストール
            if [ ! -d /opt/ros/noetic ]; then
                echo 'Installing ros-noetic-desktop-full...'
                apt update
                apt install -y ros-noetic-desktop-full
            fi

            # ROS環境をセットアップ
            source /opt/ros/noetic/setup.bash

            # ワークスペースが存在しなければビルド
            if [ ! -f /root/userdir/devel/setup.bash ]; then
                echo 'Setting up ROS workspace...'
                cd /root/userdir
                catkin_make
                source devel/setup.bash
            else
                echo 'ROS workspace already exists. Sourcing workspace...'
                source /root/userdir/devel/setup.bash
            fi

            bash
            "
        xhost -local:docker

##コンテナ作成(CUI運用)
    else
        echo "Starting Docker container in CUI mode (ROS Noetic)..."
        docker run -it \
            --name="${CONTAINER_NAME}" \
            --hostname="$HOST_NAME" \
            --volume="$WORK_DIR:/root/userdir" \
            $IMAGE_NAME bash -c "

            # ROS環境をセットアップ
            source /opt/ros/noetic/setup.bash

            # ワークスペースが存在しなければビルド
            if [ ! -f /root/userdir/devel/setup.bash ]; then
                echo 'Setting up ROS workspace...'
                cd /root/userdir
                catkin_make
                source devel/setup.bash
            else
                echo 'ROS workspace already exists. Sourcing workspace...'
                source /root/userdir/devel/setup.bash
            fi

            bash
            "
    fi
fi
