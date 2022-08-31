cd `dirname "${BASH_SOURCE[0]}"`
sudo mkdir -p "/Library/Application Support/theBigDipper/"
sudo cp ProxyConfig "/Library/Application Support/theBigDipper/"
sudo chown root:admin "/Library/Application Support/theBigDipper/SystemConfig"
sudo chmod +s "/Library/Application Support/theBigDipper/SystemConfig"

echo done
