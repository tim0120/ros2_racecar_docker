FROM ros:foxy

# Update package list
RUN apt-get update && apt-get install -y \
    lsb-release \
    curl \
    gnupg \
    locales \
    sudo \
    vim \
    emacs \
    nano \
    gedit \
    screen \
    tmux \
    iputils-ping \
    feh \
    wget \
    git \
    unzip

# Set the ROS distro
ENV ROS_DISTRO foxy

# Add the ROS keys and package
RUN sh -c 'echo "deb [arch=amd64,arm64] http://packages.ros.org/ros2/ubuntu focal main" > /etc/apt/sources.list.d/ros2-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

# Install ROS2
RUN apt-get update && apt-get install -y \
    ros-$ROS_DISTRO-desktop \
    python3-rosdep

# Set up ROS2
RUN rosdep init
RUN rosdep update

# Install VNC and things to install noVNC
RUN apt-get install -y \
    tigervnc-standalone-server \
    x11-xserver-utils \
    xterm \
    dbus-x11 \
    openbox

# Download NoVNC and unpack
ENV NO_VNC_VERSION 1.3.0
RUN wget -q https://github.com/novnc/noVNC/archive/v$NO_VNC_VERSION.zip
RUN unzip v$NO_VNC_VERSION.zip
RUN rm v$NO_VNC_VERSION.zip
RUN git clone https://github.com/novnc/websockify /noVNC-$NO_VNC_VERSION/utils/websockify

# Install the racecar simulator for ROS2
RUN apt-get install -y \
    ros-$ROS_DISTRO-compressed-image-transport \
    ros-$ROS_DISTRO-joy \
    ros-$ROS_DISTRO-map-server \
    build-essential \
    cython
ENV SIM_WS /opt/ros/sim_ws
RUN mkdir -p $SIM_WS/src
RUN git clone https://github.com/tim0120/ros2_racecar_simulator
RUN mv racecar_simulator $SIM_WS/src
RUN /bin/bash -c "source /opt/ros/$ROS_DISTRO/setup.bash; cd $SIM_WS; colcon build --symlink-install"

# Add the ROS master
ENV ROS_MASTER_URI http://racecar:11311

# Set the locale and keyboard
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
RUN apt-get install -y console-setup

# Fix some ROS things
RUN apt-get install -y \
    python3-pip
RUN pip3 install -U pip
RUN pip3 install imutils
RUN pip3 install -U matplotlib

# Kill the bell!
RUN echo "set bell-style none" >> /etc/inputrc

# Copy in the entrypoint
COPY ./entrypoint.sh /usr/bin/entrypoint.sh
COPY ./xstartup.sh /usr/bin/xstartup.sh

# Copy in default config files
COPY ./config/bash.bashrc /etc/
COPY ./config/screenrc /etc/
COPY ./config/vimrc /etc/vim/vimrc
ADD ./config/openbox /etc/X11/openbox/
COPY ./config/XTerm /etc/X11/app-defaults/
COPY ./config/default.rviz /opt/ros/$ROS_DISTRO/share/rviz/

# Create a user
RUN useradd -ms /bin/bash racecar
RUN echo 'racecar:racecar@mit' | chpasswd
RUN adduser racecar sudo
USER racecar
WORKDIR /home/racecar
