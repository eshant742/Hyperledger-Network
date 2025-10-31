#!/bin/bash

# Channel Setup Script for 4-Node Hyperledger Fabric Network
# Run this script from the orderer machine after all containers are up

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CHANNEL_NAME="mychannel"
ORDERER_ADDRESS="orderer.example.com:7050"
ORDERER_CA_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

# Function to print section headers
print_section() {
    echo -e "${YELLOW}=== $1 ===${NC}"
}

print_section "Setting up Channel: $CHANNEL_NAME"

# Create channel
print_section "Creating Channel"
# Use Org1's admin identity to create the channel
docker exec -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    cli-orderer peer channel create \
    -o $ORDERER_ADDRESS \
    -c $CHANNEL_NAME \
    -f ./channel-artifacts/channel.tx \
    --tls --cafile $ORDERER_CA_FILE

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Channel created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create channel${NC}"
    exit 1
fi

# Join Org1 to channel
print_section "Joining Org1 to Channel"
docker exec -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    cli-orderer peer channel join -b $CHANNEL_NAME.block

# Join Org2 to channel
print_section "Joining Org2 to Channel"
docker exec -e CORE_PEER_LOCALMSPID=Org2MSP \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    cli-orderer peer channel join -b $CHANNEL_NAME.block

# Join Org3 to channel
print_section "Joining Org3 to Channel"
docker exec -e CORE_PEER_LOCALMSPID=Org3MSP \
    -e CORE_PEER_ADDRESS=peer0.org3.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt \
    cli-orderer peer channel join -b $CHANNEL_NAME.block

# Update anchor peers
print_section "Updating Anchor Peers"

# Update Org1 anchor peer
docker exec -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    cli-orderer peer channel update \
    -o $ORDERER_ADDRESS \
    -c $CHANNEL_NAME \
    -f ./channel-artifacts/Org1MSPanchors.tx \
    --tls --cafile $ORDERER_CA_FILE

# Update Org2 anchor peer
docker exec -e CORE_PEER_LOCALMSPID=Org2MSP \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    cli-orderer peer channel update \
    -o $ORDERER_ADDRESS \
    -c $CHANNEL_NAME \
    -f ./channel-artifacts/Org2MSPanchors.tx \
    --tls --cafile $ORDERER_CA_FILE

# Update Org3 anchor peer
docker exec -e CORE_PEER_LOCALMSPID=Org3MSP \
    -e CORE_PEER_ADDRESS=peer0.org3.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt \
    cli-orderer peer channel update \
    -o $ORDERER_ADDRESS \
    -c $CHANNEL_NAME \
    -f ./channel-artifacts/Org3MSPanchors.tx \
    --tls --cafile $ORDERER_CA_FILE

echo -e "${GREEN}✓ Channel setup completed successfully!${NC}"
echo ""
echo "Channel '$CHANNEL_NAME' is now ready for chaincode deployment."
echo "All peers have joined the channel and anchor peers are configured."