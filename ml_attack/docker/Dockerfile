#FROM nvidia/cuda:11.0-base-ubuntu20.04
# We use tensorflow  jinwei yao(jinwei.yao@epfl.ch)
FROM tensorflow/tensorflow:2.4.0-gpu-jupyter
MAINTAINER Harma Simla <simla.harma@epfl.ch>

ENV KERAS_VERSION==2.4.3
ARG DEBIAN_FRONTEND=noninteractive

RUN rm /etc/apt/sources.list.d/cuda.list
RUN rm /etc/apt/sources.list.d/nvidia-ml.list
RUN apt-key del 7fa2af80
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub

# install some necessary tools.
RUN echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        pkg-config \
        software-properties-common
RUN apt-get install -y \
        inkscape \
        jed \
        libsm6 \
        libxext-dev \
        libxrender1 \
        lmodern \
        libcurl3-dev \
        libfreetype6-dev \
        libpng-dev \
        libzmq3-dev \
        libcupti-dev \
        pkg-config \
        ffmpeg \
        libjpeg-dev \
        libpng-dev \
        zlib1g-dev \
        locales
RUN apt-get install -y \
        sudo \
        rsync \
        cmake \
        g++ \
        swig \
        vim \
        git \
        curl \
        wget \
        unzip \
        zsh \
        git \
        screen \
        tmux \
        openjdk-8-jdk \
        openjdk-8-jre-headless \
	htop \
	python3 \
	python3-pip \
	libssl-dev \
	libffi-dev 
RUN apt install zip
#RUN apt update && \
#    apt install --no-install-recommends -y build-essential software-properties-common && \
#    add-apt-repository -y ppa:deadsnakes/ppa && \
#    apt install --no-install-recommends -y python3.7 python3.7-dev python3.7-distutils
#
#RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
#RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
#
## Upgrade pip to latest version
#RUN curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
#    python3 get-pip.py --force-reinstall && \
#    rm get-pip.py
#
#RUN pip install --upgrade keyrings.alt

RUN apt-get install -y openssh-server

# python
RUN pip install --upgrade pip
RUN pip install pycwt
RUN pip install numpy \
	keras==${KERAS_VERSION} \
	h5py \
	scipy \
        scikit-learn \
	sklearn \
	pandas \
        s3cmd \
	matplotlib \
        wandb
#RUN pip install -Iv sktime==0.13.2
# configure environments.
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Configure user and group
ENV SHELL=/bin/bash \
    NB_USER=user \
    NB_UID=111111\
    NB_GROUP=instruction-identification \
    NB_GID=111111
ENV HOME=/home/$NB_USER

COPY base/fix-permissions base/entrypoint.sh base/launch.sh base/launch_and_sleep.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/fix-permissions
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/launch.sh
RUN chmod +x /usr/local/bin/launch_and_sleep.sh
RUN groupadd $NB_GROUP -g $NB_GID
RUN useradd -m -s /bin/bash -N -u $NB_UID -g $NB_GID $NB_USER && \
    echo "${NB_USER}:${NB_USER}" | chpasswd && \
    usermod -aG sudo,adm,root ${NB_USER} && \
    fix-permissions $HOME
RUN echo 'user ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
# Default ssh config file that skips (yes/no) question when first login to the host
RUN mkdir /var/run/sshd
RUN  sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config \
  && sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config \
  && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
  && sed -i "s/#AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config
RUN /usr/bin/ssh-keygen -A

ENV SSHDIR $HOME/.ssh
RUN mkdir -p $SSHDIR \
    && chmod go-w $HOME/ \
    && chmod 700 $SSHDIR \
    && touch $SSHDIR/authorized_keys \
    && chmod 600 $SSHDIR/authorized_keys \
    && chown -R ${NB_USER}:${NB_GROUP} ${SSHDIR} \
    && chown -R ${NB_USER}:${NB_GROUP} /etc/ssh/*
### The above instruction gives us the permission

###### switch to user and compile test example.
USER ${NB_USER}
RUN ssh-keygen -b 2048 -t rsa -f $SSHDIR/id_rsa -q -N ""
RUN cat ${SSHDIR}/*.pub >> ${SSHDIR}/authorized_keys
RUN echo "StrictHostKeyChecking no" > ${SSHDIR}/config

###### switch to root
# expose port for ssh and start ssh service.
EXPOSE 22
# expose port for notebook.
EXPOSE 8888
# expose port for tensorboard.
EXPOSE 6666

WORKDIR /home/user
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]
