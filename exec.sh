#!/bin/bash

CONTAINER_NAME="rov_ros_noetic_cui"

while [[ $# -gt 0 ]]; do
    case $1 in
        --GUI)
            CONTAINER_NAME="rov_ros_noetic_gui"
            shift
            shift
            ;;
        --CUI)
            CONTAINER_NAME="rov_ros_noetic_cui"
            shift
            shift
            ;;
        --)
            shift
            break
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

docker exec -it $CONTAINER_NAME bash 
