FROM fedora:25 as builder

# arguments
ARG USER=agomezl
ARG HOME=/home/${USER}
ARG POLYML_DIR=${HOME}/opt/polyml
ARG REPO_URL=https://storage.googleapis.com/git-repo-downloads/repo

# basic stuff
RUN dnf -y group install 'Development Tools'
RUN dnf -y install gcc-c++ git sudo wget python

# Add user
RUN useradd -ms /bin/bash ${USER} && \
    echo "${USER}:docker" | chpasswd && \
    usermod -a -G wheel ${USER} && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER agomezl
WORKDIR ${HOME}

RUN mkdir -p .local/bin && \
    curl ${REPO_URL} > ~/.local/bin/repo && \
    chmod a+x ~/.local/bin/repo

ENV PATH ${HOME}/.local/bin/:${HOME}/HOL/bin/:${POLYML_DIR}/bin/:${PATH}

RUN repo init \
    -m master.xml \
    --repo-url=https://gerrit.googlesource.com/git-repo \
    --no-clone-bundle \
    --depth=1 \
    -u https://github.com/agomezl/cake-manifest.git && \
     repo sync

RUN cd polyml && \
    ./configure --prefix=${POLYML_DIR} && \
    make && make compiler && make install && \
    cd .. && rm -fr polyml

RUN cd hol && \
    poly < tools/smart-configure.sml && \
    bin/build

RUN cd cakeml/ && \
    Holmake

RUN repo manifest -r > latest.xml

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
COPY --from=builder --chown=agomezl ${HOME}/latest.xml ${HOME}/latest.xml
