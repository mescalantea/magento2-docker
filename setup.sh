#!/bin/bash
if [ ! -f .env ]; then
    cp .env.sample .env
fi

ngrok=0
build=0

# Parse arguments:
# --build: Build of docker images
# --ngrok-token=YOUR_NGROK_TOKEN: Override the ngrok token in .env
# --ngrok=0: Skip ngrok setup
while [[ "$#" -gt 0 ]]; do
    if [ "$1" == "--ngrok" ]; then
        ngrok=1
    elif [ "$1" == "--build" ]; then
        build=1
    elif [[ "$1" == --ngrok-token=* ]]; then
        ngrok_token="${1#*=}"
        sed -i.bak "s|NGROK_AUTHTOKEN=.*|NGROK_AUTHTOKEN=$ngrok_token|" .env
        rm .env.bak
    fi
    shift
done

# Reset PUBLIC_URL inside .env
sed -i.bak "s|PUBLIC_URL=.*|PUBLIC_URL=|" .env
rm .env.bak

set -o allexport
source .env
set +o allexport

if [ $ngrok -eq 1 ]; then

    if [ -z "$NGROK_AUTHTOKEN" ]; then
        echo "❌ Please set NGROK_AUTHTOKEN with your ngrok auth token in your .env file (get it from https://dashboard.ngrok.com/)"
        exit 1
    fi
    
    echo "🚀 Starting ngrok..."

    docker run -d -e NGROK_AUTHTOKEN=$NGROK_AUTHTOKEN \
        -p $NGROK_PORT:4040 \
        --name $NGROK_CONTAINER_NAME \
        --add-host=host:host-gateway \
        ngrok/ngrok:alpine \
        http host:$WP_HTTP_PORT
    
    M2_URL=""
    retry=10
    timeout=1
    start=$(date +%s)
    while [ -z "$M2_URL" ]; do
        sleep $timeout
        M2_URL=$(curl -s http://localhost:$NGROK_PORT/api/tunnels | grep -o '"public_url":"[^"]*"' | sed 's/"public_url":"\(.*\)"/\1/' | head -n 1)
        if [ $(($(date +%s) - $start)) -gt $retry ]; then
            docker rm -f $NGROK_CONTAINER_NAME || true
            echo "❌ Error getting public url from ngrok after ${retry} seconds"
            exit 1
        fi
    done

    # Overwrite PUBLIC_URL inside .env
    sed -i.bak "s|PUBLIC_URL=.*|PUBLIC_URL=$M2_URL|" .env
    rm .env.bak

    echo "✅ Ngrok started. Public URL: $M2_URL"
fi

if [ $build -eq 1 ]; then
    docker compose up -d --build || exit 1
else
    docker compose up -d || exit 1
fi

echo "🚀 Waiting for installation to complete..."

retry=120
timeout=1
start=$(date +%s)
while [ $(($(date +%s) - $start)) -lt $retry ]; do
    if docker compose exec web ls /var/www/html/.post-install-complete > /dev/null 2>&1; then
        seconds=$(($(date +%s) - $start))
        echo "✅ Done in ${seconds} seconds."
        echo "🔗 Browse products at ${M2_URL}"
        echo "🔗 Access Admin at ${M2_URL}/admin"
        echo "User: $M2_ADMIN_USER"
        echo "Password: $M2_ADMIN_PASSWORD"
        exit 0
    elif docker compose exec web ls /var/www/html/.post-install-failed > /dev/null 2>&1; then
        seconds=$(($(date +%s) - $start))
        echo "❌ Installation failed after ${seconds} seconds."
        exit 1
    fi
    sleep $timeout
done
echo "❌ Timeout after ${retry} seconds"
exit 1