#!/bin/bash
set -xe

export DEBIAN_FRONTEND=noninteractive

# Install prerequisites
sudo apt-get update -q
sudo apt-get install -y -q \
  dpkg-dev \
  zlib1g-dev \
  libssl-dev \
  openssl \
  procps \
  rsync \
  ca-certificates \
  build-essential \
  git \
  gnupg \
  curl \
  unzip \
  locales \
  net-tools \
  systemd \
  wireguard-dkms

# Set locale
sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
sudo locale-gen
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# Install asdf ruby
if [ ! -d $HOME/.asdf ]; then
  git clone --depth 1 https://github.com/asdf-vm/asdf.git $HOME/.asdf
fi
grep -qxF '. $HOME/.asdf/asdf.sh' $HOME/.bashrc || echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc
grep -qxF '. $HOME/.asdf/completions/asdf.bash' $HOME/.bashrc || echo '. $HOME/.asdf/completions/asdf.bash' >> $HOME/.bashrc
. $HOME/.asdf/asdf.sh
asdf list ruby || asdf plugin-add ruby
cd /vagrant
asdf install

# Install omnibus
cd omnibus
gem install bundler
bundle install --binstubs

# Build omnibus package
sudo mkdir -p /opt/firezone
sudo chown -R ${USER} /opt/firezone
bin/omnibus build firezone

sudo dpkg -i pkg/firezone*.deb

# Usually fails the first time
sudo firezone-ctl reconfigure || true

sudo firezone-ctl restart
