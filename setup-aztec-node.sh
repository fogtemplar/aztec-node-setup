# 1) 새 프로젝트 디렉토리로 이동
mkdir aztec-node-setup && cd aztec-node-setup

# 2) 기존 setup-aztec-node.sh 복사 또는 새로 만들기
cp /path/to/your/setup-aztec-node.sh .

# 3) 실행 권한 설정
chmod +x setup-aztec-node.sh

# 4) README, .gitignore, LICENSE 작성 (선택)
cat > README.md <<EOF
# Aztec 풀 노드 자동 설치 스크립트

v0.85.0-alpha-testnet.5 기준으로 Ubuntu/Debian에 Aztec Sequencer Node를  
한 번에 설치·가동하는 Bash 스크립트입니다.

## 사용법
\`\`\`bash
git clone https://github.com/YourUsername/aztec-node-setup.git
cd aztec-node-setup
chmod +x setup-aztec-node.sh
sudo ./setup-aztec-node.sh
\`\`\`
EOF

echo "node_modules/" > .gitignore

# 5) Git 초기화, 커밋
git init
git add .
git commit -m "Initial commit: Aztec node setup script"
