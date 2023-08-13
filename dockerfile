FROM ubuntu:latest

# install all dependencies
RUN apt-get update && apt-get install language-pack-en zsh sudo git wget curl binutils npm nasm build-essential -y

# switch default shell
RUN chsh -s $(which zsh)

# setup non-root user that also works with vscode container dev plugin.
# we don't want viruses to have root by default.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN git clone https://github.com/powerline/fonts.git --depth=1 \
    && cd fonts && ./install.sh && cd .. && rm -rf fonts

ARG TARGETARCH
RUN arch=$TARGETARCH \
    && if [ "$arch" = "amd64" ]; then arch="x86_64"; else arch="arm64"; fi \
    && wget https://github.com/bazelbuild/bazel/releases/download/6.3.2/bazel-6.3.2-linux-$arch \
    && chmod +x bazel-6.3.2-linux-$arch \
    && mv bazel-6.3.2-linux-$arch /usr/bin/bazel

# set default user
USER $USERNAME

# Since containers will run locally with the repo in a shared drive
# it is safe to have users commit inside of containers. Since no key is
# setup, containers don't have permission to push.
RUN git config --global --add safe.directory "*" \
    # makes pagination better in container
    && git config --global core.pager 'less -+F -+X'

RUN cd ~ && sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
COPY --chown=$USERNAME:$USERNAME .zshrc /home/$USERNAME/

# We want the container to be the main dev place.
CMD ["/bin/zsh"]
