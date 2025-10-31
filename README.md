# Hyperledger Fabric: 4-Node Distributed Network Project

This project demonstrates a multi-host Hyperledger Fabric network setup, consisting of one Orderer node and three Peer Organization nodes, distributed across four separate machines.

## 👨‍💻 Team Members

* **Eshant Gupta** (Orderer-IP: 10.116.17.64)
* **Aditya Singh Chandel** (Org1-IP: 10.116.17.141)
* **Shresth Sharma** (Org2-IP: 10.116.17.169)
* **Arun Kumar Swami** (Org3-IP: 10.116.17.26)

---

## 📖 Project Report

For a complete overview of the project, architecture, and proof of the distributed setup, please see the full report:
**[./project-report/Hyperledger Fabric Network Setup.pdf](./project-report/Hyperledger%20Fabric%20Network%20Setup.pdf)**

---

## 🚀 How to Run (Local Single-Machine Test)

This guide allows you to run the *entire* 4-node network on your local machine for testing and grading.

### Prerequisites

1.  **Docker & Docker Compose:** Ensure you have them installed.
2.  **Hyperledger Fabric Binaries:** You must have the `cryptogen` and `configtxgen` tools.
    * *If you don't:* `curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- -f 2.5.12 -b 2.5.12`
    * (Make sure the downloaded `bin` directory is in your PATH).

### Step 1: Generate Network Artifacts

First, we generate all the crypto material and channel configurations.

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the generation script
./scripts/generate-artifacts.sh
```
You will now have `crypto-config` and `channel-artifacts` folders.

### Step 2: Launch the Network

We will use the special `docker-compose-local-test.yaml` file to launch all 4 nodes.

```bash
docker-compose -f docker-compose-local-test.yaml up -d
```
You can check if all containers are running with `docker ps`. You should see `orderer.example.com`, `peer0.org1.example.com`, `peer0.org2.example.com`, `peer0.org3.example.com`, and `cli-orderer`.

### Step 3: Setup the Channel

Now, we will enter the `cli-orderer` container to create the channel, join all peers, and update anchor peers.

```bash
docker exec -it cli-orderer bash
```
Once inside the container, run the channel setup script:
```bash
# (You are now inside the 'cli-orderer' container)
./scripts/channel-setup.sh
```
This will output `✓ Channel setup completed successfully!`.

### Step 4: Deploy and Test Chaincode

While still inside the `cli-orderer` container, deploy the chaincode.

```bash
# (You are still inside the 'cli-orderer' container)
./scripts/deploy-chaincode.sh
```
This script will package, install, approve, and commit the chaincode, and finally invoke `InitLedger`.

### Step 5: Verify the Ledger

Let's test the chaincode! [cite_start](These commands are from the project report [cite: 204, 206, 207, 209]).

**1. Query all assets (should show 6 assets):**
```bash
peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'
```

**2. Query 'asset1' (Owner should be Tomoko):**
```bash
peer chaincode query -C mychannel -n basic -c '{"Args":["ReadAsset","asset1"]}'
```

**3. Transfer 'asset1' to a new owner ("Juvin"):**
```bash
peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $ORDERER_CA \
    -C mychannel -n basic \
    --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
    --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles $PEER0_ORG2_CA \
    --peerAddresses peer0.org3.example.com:7051 --tlsRootCertFiles $PEER0_ORG3_CA \
    -c '{"function":"TransferAsset","Args":["asset1","Juvin"]}'
```

**4. Query 'asset1' again (Owner should now be Juvin):**
```bash
peer chaincode query -C mychannel -n basic -c '{"Args":["ReadAsset","asset1"]}'
```

**To exit the CLI container, type `exit`.**

### Step 6: Teardown the Network

To stop and remove all containers, volumes, and networks:

```bash
docker-compose -f docker-compose-local-test.yaml down -v
rm -rf crypto-config channel-artifacts
```

---

## 🏛️ Original Distributed (Multi-Machine) Setup

This section documents how the project was *originally* built across 4 machines. (These steps are for documentation only).

1.  **Generate Artifacts:** On the Orderer machine (10.116.17.64), run `./scripts/generate-artifacts.sh`.
2.  **Distribute Files:** Copy the *entire* project directory (including the generated `crypto-config` and `channel-artifacts`) to all 3 peer machines.
3.  **Start Network:** On *each* machine, run its specific docker-compose file:
    * **Orderer Machine:** `docker-compose -f docker-compose-orderer.yaml up -d`
    * **Org1 Machine:** `docker-compose -f docker-compose-org1.yaml up -d`
    * **Org2 Machine:** `docker-compose -f docker-compose-org2.yaml up -d`
    * **Org3 Machine:** `docker-compose -f docker-compose-org3.yaml up -d`
4.  **Setup Channel:** On the **Orderer machine**, run `docker exec -it cli-orderer bash` and then run `./scripts/channel-setup.sh`.
5.  **Deploy Chaincode:** On the **Orderer machine**, inside the `cli-orderer` container, run `./scripts/deploy-chaincode.sh`.
