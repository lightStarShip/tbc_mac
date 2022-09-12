#!/bin/sh

#  install_helper.sh

cd "$(dirname "${BASH_SOURCE[0]}")"

sudo mkdir -p "/Library/Application Support/TheBigDipper/"
sudo cp ProxyConfig "/Library/Application Support/TheBigDipper/"
sudo chown root:admin "/Library/Application Support/TheBigDipper/ProxyConfig"
sudo chmod a+rx "/Library/Application Support/TheBigDipper/ProxyConfig"
sudo chmod +s "/Library/Application Support/TheBigDipper/ProxyConfig"

echo done
