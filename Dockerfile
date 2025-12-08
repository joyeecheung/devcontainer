###############
# Stage: setup: set up environment and install dependencies
###############
FROM ubuntu:latest AS setup

ARG USER_UID=900
ARG USER_GID=$USER_UID

# Create user, install sudo, configure environment and ccache, copy scripts
RUN groupadd --gid $USER_GID developer \
  && useradd --uid $USER_UID --gid $USER_GID --shell /bin/bash --create-home developer \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends sudo \
  && echo 'developer ALL=NOPASSWD: ALL' >> /etc/sudoers.d/developer \
  && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

ENV DEBIAN_FRONTEND=1
ENV PATH=/usr/lib/ccache:$PATH

COPY --chown=root:developer --chmod=0755 ./scripts/ /home/developer/scripts/
RUN /home/developer/scripts/install.sh && /home/developer/scripts/ccache.sh

################
# Stage: clone the Node.js repository
################
FROM setup AS clone
USER developer
RUN /home/developer/scripts/clone.sh

###############
# Stage: build the Node.js source code
###############
FROM clone AS build
RUN /home/developer/scripts/build.sh

###################
# Stage: install the local build and node-core-utils
###################
FROM build AS postbuild
ENV PATH=/home/developer/.local/bin:$PATH
WORKDIR /home/developer/nodejs/node
RUN /home/developer/scripts/install-node.sh && /home/developer/scripts/ncu.sh

########################
# Final image (postbuild)
########################
FROM postbuild AS final

