#!/bin/sh

if [ -n "$DESTDIR" ] ; then
    case $DESTDIR in
        /*) # ok
            ;;
        *)
            /bin/echo "DESTDIR argument must be absolute... "
            /bin/echo "otherwise python's distutils will bork things."
            exit 1
    esac
fi

echo_and_run() { echo "+ $@" ; "$@" ; }

echo_and_run cd "/root/userdir/src/uuv_simulator/uuv_control/uuv_control_cascaded_pids"

# ensure that Python install destination exists
echo_and_run mkdir -p "$DESTDIR/root/userdir/install/lib/python3/dist-packages"

# Note that PYTHONPATH is pulled from the environment to support installing
# into one location when some dependencies were installed in another
# location, #123.
echo_and_run /usr/bin/env \
    PYTHONPATH="/root/userdir/install/lib/python3/dist-packages:/root/userdir/build/lib/python3/dist-packages:$PYTHONPATH" \
    CATKIN_BINARY_DIR="/root/userdir/build" \
    "/usr/bin/python3" \
    "/root/userdir/src/uuv_simulator/uuv_control/uuv_control_cascaded_pids/setup.py" \
     \
    build --build-base "/root/userdir/build/uuv_simulator/uuv_control/uuv_control_cascaded_pids" \
    install \
    --root="${DESTDIR-/}" \
    --install-layout=deb --prefix="/root/userdir/install" --install-scripts="/root/userdir/install/bin"
