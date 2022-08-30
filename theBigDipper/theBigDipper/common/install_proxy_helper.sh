cd `dirname "${BASH_SOURCE[0]}"`

sudo mkdir -p "/Library/Application Support/TheBigDipper/"
sudo cp sysproxyconfig "/Library/Application Support/TheBigDipper/"
sudo chown root:admin "/Library/Application Support/TheBigDipper/SystemConfig"
sudo chmod +s "/Library/Application Support/TheBigDipper/SystemConfig"

echo done
