FROM fedora:25 as builder

# arguments
ARG USER=agomezl
ARG HOME=/home/${USER}
ARG POLYML_DIR=${HOME}/opt/polyml

# basic stuff
RUN dnf -y group install 'Development Tools'
RUN dnf -y install gcc-c++ git sudo wget

# Add user
RUN useradd -ms /bin/bash ${USER} && \
    echo "${USER}:docker" | chpasswd && \
    usermod -a -G wheel ${USER} && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER agomezl
WORKDIR ${HOME}

RUN git clone --depth=1 https://github.com/polyml/polyml.git -b v5.7 && \
    cd polyml && \
    ./configure --prefix=${POLYML_DIR} && \
    make && make compiler && make install && \
    cd .. && rm -fr polyml

ENV PATH ${POLYML_DIR}/bin/:${PATH}

RUN git clone --depth=1 https://github.com/HOL-Theorem-Prover/HOL.git && \
    cd HOL && \
    poly < tools/smart-configure.sml && \
    bin/build

ENV PATH ${HOME}/HOL/bin/:${PATH}

RUN git clone --depth=1 https://github.com/CakeML/cakeml.git && \
    cd cakeml/ && \
    Holmake

FROM fedora:25

# arguments
ARG USER=agomezl
ARG HOME=/home/${USER}
ARG POLYML_DIR=${HOME}/opt/polyml

RUN dnf -y install git sudo

# Add user
RUN useradd -ms /bin/bash ${USER} && \
    echo "${USER}:docker" | chpasswd && \
    usermod -a -G wheel ${USER} && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER agomezl
WORKDIR ${HOME}

RUN mkdir -p ${POLYML_DIR} ${HOME}/HOL ${HOME}/cakeml
COPY --from=builder --chown=agomezl ${POLYML_DIR} ${POLYML_DIR}/
ENV PATH ${POLYML_DIR}/bin/:${PATH}
COPY --from=builder --chown=agomezl ${HOME}/HOL ${HOME}/HOL/
ENV PATH ${HOME}/HOL/bin/:${PATH}
COPY --from=builder --chown=agomezl ${HOME}/cakeml ${HOME}/cakeml/
