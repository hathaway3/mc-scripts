#!/bin/bash

# Define variables
BEDROCK_USER="bedrock"
SERVER_DIR="/home/$BEDROCK_USER"

echo "Fetching the latest Minecraft Bedrock server download URL..."
#DOWNLOAD_URL=$(wget -qO- https://www.minecraft.net/en-us/download/server/bedrock | grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' | head -1)

DOWNLOAD_URL="https://minecraft.azureedge.net/bin-linux/bedrock-server-1.20.41.02.zip"

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to fetch download URL. Exiting."
    exit 1
fi
echo "Download URL fetched."

echo "Creating the bedrock user..."
if useradd -m -d "$SERVER_DIR" -s /bin/bash $BEDROCK_USER; then
    echo "User created successfully."
else
    echo "Failed to create user. Exiting."
    exit 1
fi

echo "Downloading Minecraft Bedrock Server..."
if wget -O "$SERVER_DIR/bedrock-server.zip" $DOWNLOAD_URL; then
    echo "Download successful."
    unzip "$SERVER_DIR/bedrock-server.zip" -d "$SERVER_DIR"
    rm "$SERVER_DIR/bedrock-server.zip"
    echo "Server files extracted."
else
    echo "Failed to download. Exiting."
    exit 1
fi

echo "Accepting EULA..."
echo "eula=true" > "$SERVER_DIR/eula.txt"
echo "EULA accepted."

echo "Installing 'Screen' package..."
if apt-get update && apt-get install -y screen; then
    echo "'Screen' installed successfully."
else
    echo "Failed to install 'Screen'. Exiting."
    exit 1
fi

echo "Creating an init script for the Minecraft server..."
cat <<EOF > /etc/init.d/minecraft
#!/bin/sh
### BEGIN INIT INFO
# Provides:          minecraft
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Minecraft server
# Description:       This service starts the Minecraft server
### END INIT INFO

case "\$1" in
  start)
    echo "Starting Minecraft server..."
    su - $BEDROCK_USER -c "cd $SERVER_DIR; screen -dmS minecraft ./bedrock_server"
    ;;
  stop)
    echo "Stopping Minecraft server..."
    su - $BEDROCK_USER -c "screen -S minecraft -X quit"
    ;;
  *)
    echo "Usage: /etc/init.d/minecraft {start|stop}"
    exit 1
    ;;
esac

exit 0
EOF

if chmod +x /etc/init.d/minecraft && update-rc.d minecraft defaults; then
    echo "Minecraft init script created and enabled."
else
    echo "Failed to create or enable init script. Exiting."
    exit 1
fi

echo "Starting the Minecraft server..."
if /etc/init.d/minecraft start; then
    echo "Minecraft server started successfully."
else
    echo "Failed to start the Minecraft server. Exiting."
    exit 1
fi

echo "Setup complete."

