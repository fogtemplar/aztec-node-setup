#!/usr/bin/env bash
set -euo pipefail

# ====================================================
# Aztec alpha-testnet 풀 노드 자동 설치 & 가동 스크립트
# Version: v0.85.0-alpha-testnet.5
# Ubuntu/Debian 전용, sudo 권한 필요
# ====================================================

# 1) 루트 권한 확인
if [ "$(id -u)" -ne 0 ]; then
  echo "⚠️  이 스크립트는 root(또는 sudo) 권한으로 실행해야 합니다."
  exit 1
fi

# 2) Docker & Docker Compose 설치
echo "🐋 Docker & Docker Compose 설치..."
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 3) Node.js 설치
echo "🟢 Node.js 설치..."
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs

# 4) Aztec CLI 설치 및 alpha-testnet 준비
echo "⚙️ Aztec CLI 설치 및 alpha-testnet 준비..."
curl -sL https://install.aztec.network | bash

# 설치된 바이너리 경로를 PATH에 추가
export PATH="$HOME/.aztec/bin:$PATH"

# 설치 확인
if ! command -v aztec-up &> /dev/null; then
  echo "❌ Aztec CLI 설치에 실패했습니다."
  exit 1
fi

# alpha-testnet용 바이너리 다운로드
aztec-up alpha-testnet

# 5) 사용자 입력
read -p "▶️ L1 실행 클라이언트(EL) RPC URL: " ETH_RPC
read -p "▶️ L1 컨센서스(CL) RPC URL: " CONS_RPC
read -p "▶️ Blob Sink URL (없으면 Enter): " BLOB_URL

# 6) 공인 IP 자동 조회
echo "🌐 공인 IP 조회 중..."
PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
echo "    → $PUBLIC_IP"

# 7) .env 파일 생성
cat > .env <<EOF
ETHEREUM_HOSTS="$ETH_RPC"
L1_CONSENSUS_HOST_URLS="$CONS_RPC"
P2P_IP="$PUBLIC_IP"
EOF

if [ -n "$BLOB_URL" ]; then
  echo "BLOB_SINK_URL=\"$BLOB_URL\"" >> .env
fi

# 8) docker-compose.yml 생성
BLOB_FLAG=""
if [ -n "$BLOB_URL" ]; then
  BLOB_FLAG="--sequencer.blobSinkUrl \$BLOB_SINK_URL"
fi

cat > docker-compose.yml <<EOF
version: "3.8"
services:
  node:
    image: aztecprotocol/aztec:0.85.0-alpha-testnet.5
    network_mode: host
    env_file:
      - .env
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
        start --network alpha-testnet --node --archiver \
        --l1-rpc-urls \$ETHEREUM_HOSTS \
        --l1-consensus-host-urls \$L1_CONSENSUS_HOST_URLS \
        --p2p.p2pIp \$P2P_IP $BLOB_FLAG'
    volumes:
      - \${PWD}/data:/data
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8080:8080
EOF

# 9) 데이터 디렉터리 준비
mkdir -p data

# 10) 서비스 시작
echo "🚀 Aztec 풀 노드 시작 (docker-compose up -d)..."
docker-compose up -d

echo -e "\n✅ 설치 및 가동 완료!"
echo "   - 로그 확인: docker-compose logs -f"
echo "   - 데이터 디렉터리: $(pwd)/data"
