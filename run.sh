#!/bin/bash  

WORK_DIR="$(pwd)/userdir"
IMAGE_NAME="ros:noetic"
CONTAINER_NAME="rov_ros_noetic"  
HOST_NAME="rov_noetic_cui"
GUI_MODE=false
GIT_URL="https://github.com/soso1729/rov_docker_system.git"

# システムを更新
sudo apt update && sudo apt upgrade -y

# 最新のソースコードを取得
git pull origin main

# Dockerのインストール確認
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

    # Dockerサービスの起動と有効化
    sudo systemctl start docker
    sudo systemctl enable docker

fi

# オプション解析
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

# ROSワークスペースディレクトリの作成
if [ ! -d "$WORK_DIR" ]; then
    echo "Creating ROS workspace directory at $WORK_DIR"
    mkdir -p "$WORK_DIR/src"
fi

# 既存コンテナの確認
container_exists=$(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}')

# ROS NoeticのDockerイメージを取得
docker pull "$IMAGE_NAME"

if [ "$container_exists" == "$CONTAINER_NAME" ]; then
    xhost +local:docker
    echo "Container $CONTAINER_NAME already exists. Starting it..."
    docker start -ai "$CONTAINER_NAME"
else
    echo "Creating a new container $CONTAINER_NAME..."

    ## コンテナ作成(GUI運用)
    if [ "$GUI_MODE" = true ]; then

        cd ~/rov_docker_system/userdir/src
        git clone https://github.com/fredvaz/bluerov2.git
        git clone https://github.com/arturmiller/uuv_simulator.git

        # X11ディレクトリの確認
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
            --volume="$WORK_DIR:/root/userdir" \
            $IMAGE_NAME bash -c "

            roscore &

            # OpenGLライブラリのインストール
            apt update && apt install -y libgl1-mesa-glx libgl1-mesa-dri

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

            echo 'keyboard-configuration keyboard-configuration/layoutcode string jp' | debconf-set-selections &&
            echo 'keyboard-configuration keyboard-configuration/modelcode string pc105' | debconf-set-selections &&
            echo 'keyboard-configuration keyboard-configuration/xkb-keymap select jp' | debconf-set-selections &&


            # 各パッケージのインストール
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
            ros-noetic-xacro

            ## シンボリックリンクの作成
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

    ## コンテナ作成(CUI運用)
    else

        cd ~/rov_docker_system/userdir/src
        git clone https://github.com/fredvaz/bluerov2.git
        git clone https://github.com/arturmiller/uuv_simulator.git

        echo "Starting Docker container in CUI mode (ROS Noetic)..."
        docker run -it \
            --name="${CONTAINER_NAME}" \
            --hostname="$HOST_NAME" \
            --volume="$WORK_DIR:/root/userdir" \
            --env="LIBGL_ALWAYS_SOFTWARE=1" \
            $IMAGE_NAME bash -c "

            # OpenGLライブラリのインストール
            apt update && apt install -y libgl1-mesa-glx libgl1-mesa-dri

            # ROS環境をセットアップ
            source /opt/ros/noetic/setup.bash

            roscore &
            
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

            echo 'keyboard-configuration keyboard-configuration/layoutcode string jp' | debconf-set-selections &&
            echo 'keyboard-configuration keyboard-configuration/modelcode string pc105' | debconf-set-selections &&
            echo 'keyboard-configuration keyboard-configuration/xkb-keymap select jp' | debconf-set-selections &&


            # 各パッケージのインストール
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
            ros-noetic-xacro

            ## シンボリックリンクの作成
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
