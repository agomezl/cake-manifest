FROM fedora:25 as builder

# arguments
ARG USER=agomezl
ARG HOME=/home/${USER}
ARG POLYML_DIR=${HOME}/opt/polyml
ARG REPO_URL=https://storage.googleapis.com/git-repo-downloads/repo
ARG CAKEML_REPO=https://github.com/agomezl/cake-manifest.git
ARG CAKEML_REPO_BRANCH=master
ARG CAKEML_MANIFEST=master.xml

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

ENV PATH ${HOME}/.local/bin/:${HOME}/hol/bin/:${POLYML_DIR}/bin/:${PATH}

RUN repo init \
    --manifest-name=${CAKEML_MANIFEST} \
    --manifest-branch=${CAKEML_REPO_BRANCH} \
    --manifest-url=${CAKEML_REPO} \
    --repo-url=https://gerrit.googlesource.com/git-repo \
    --no-clone-bundle \
    --depth=1 && \

     repo sync

RUN cd polyml && \
    ./configure --prefix=${POLYML_DIR} && \
    make && make compiler && make install

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

RUN mkdir -p ${POLYML_DIR} ${HOME}/hol ${HOME}/cakeml
COPY --from=builder --chown=agomezl ${POLYML_DIR} ${POLYML_DIR}/
ENV PATH ${POLYML_DIR}/bin/:${PATH}
COPY --from=builder --chown=agomezl ${HOME}/hol ${HOME}/hol/
ENV PATH ${HOME}/hol/bin/:${PATH}
COPY --from=builder --chown=agomezl ${HOME}/cakeml ${HOME}/cakeml/
COPY --from=builder --chown=agomezl ${HOME}/latest.xml ${HOME}/latest.xml
