#!/bin/bash

mkdir -p files/root
pushd files/root

# Clone oh-my-zsh repository
if [ ! -d "./.oh-my-zsh" ]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh ./.oh-my-zsh
fi

# Install extra plugins
if [ ! -d "./.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ./.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [ ! -d "./.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ./.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi
if [ ! -d "./.oh-my-zsh/custom/plugins/zsh-completions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-completions ./.oh-my-zsh/custom/plugins/zsh-completions
fi

# Get .zshrc dotfile
cp -f $GITHUB_WORKSPACE/scripts/.zshrc .

popd
