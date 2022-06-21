
get_config_files(){
read -p "Download testnet config files? this will remove the current config files (y/n) : " ans
if [[ ${ans} == "y" ]]; then
    echo -e "\n- Removing configuration files\n"
    rm -rv configuration
    echo -e "\n- Downloading configuration files\n"
    URL_CONFIG_FILES=$(curl -s https://api.github.com/repos/input-output-hk/cardano-node/releases/latest | jq -r .body | grep 'Configuration files' | sed 's/\(- \[Configuration files\]\)//' | tr -d '()\r' | sed 's/\/index\.html//')
    wget -P ${PWD}/configuration $URL_CONFIG_FILES/testnet-config.json \
    $URL_CONFIG_FILES/testnet-byron-genesis.json \
    $URL_CONFIG_FILES/testnet-shelley-genesis.json \
    $URL_CONFIG_FILES/testnet-alonzo-genesis.json \
    $URL_CONFIG_FILES/testnet-topology.json
    echo -e "\n- Updating configurationfiles .. changing stdout logs to a file log destination \n"
    sed -i 's/StdoutSK/FileSK/' ${PWD}/configuration/testnet-config.json
    sed -i 's/stdout/\/node\/logs\/node.log/' ${PWD}/configuration/testnet-config.json
fi
}

check_missing_files(){
file_missing=false
if ! [[ -e ${PWD}/configuration/testnet-config.json ]]; then
    echo -e "\nError - testnet-config.json file missing"
    exit
fi
if ! [[ -e ${PWD}/configuration/testnet-byron-genesis.json ]]; then
    echo -e "\nError - testnet-byron-genesis.json file missing"
    exit
fi
if ! [[ -e ${PWD}/configuration/testnet-shelley-genesis.json ]]; then
    echo -e "\nError - testnet-shelley-genesis.json file missing"
    exit
fi
if ! [[ -e ${PWD}/configuration/testnet-alonzo-genesis.json ]]; then
    echo -e "\nError - testnet-alonzo-genesis.json file missing"
    exit
fi
if ! [[ -e ${PWD}/configuration/testnet-topology.json ]]; then
    echo -e "\nError - testnet-topology.json file missing"
    exit
fi
if ! [[ -e ${PWD}/env ]]; then
    echo -e "\nError - env file missing"
    exit
fi
}

get_config_files
check_missing_files

echo -e "\n- Found configuration files :\n$(ls configuration) \n"

HOSTADDR="0.0.0.0"
PORT="6000"
TOPOLOGY="/node/configuration/testnet-topology.json"
CONFIG="/node/configuration/testnet-config.json"
DBPATH="/db"
SOCKETPATH="/node/node.socket"

echo -e "- Docker container will run cardano-node with the following parameters :\nhost : ${HOSTADDR}\nport: ${PORT}\ntopology: ${TOPOLOGY}\nconfig: ${CONFIG}\ndbpath: ${DBPATH}\nsocketpath: ${SOCKETPATH}\n"
echo -e "- Docker container will bind the following directories :\n$PWD/configuration/ \n$PWD/db/ \n$PWD/logs/ \n"

docker run  -d \
    -v $PWD/configuration/:/node/configuration \
    -v $PWD/db/:/node/db \
    -v $PWD/logs/:/node/logs \
    --env-file env \
    --entrypoint cardano-node \
    inputoutput/cardano-node \
    run \
    --topology ${TOPOLOGY} \
    --database-path ${DBPATH} \
    --socket-path ${SOCKETPATH} \
    --host-addr ${HOSTADDR} \
    --port ${PORT} \
    --config ${CONFIG}

# * -v $PWD/configuration/:/configuration - bind mount the configuration directory from the host in the container into the /configuration directory
# * -v $PWD/db/:/db \ - bind mount the db directory from the host in the container into the /db directory
# * -v $PWD/logs/:/logs - bind mount the logs directory from the host in the container into the /logs directory
# * --env-file env \ - set environment variables from env file
# --entrypoint cardano-node \ - the main command when running the container
# inputoutput/cardano-node \ - the official iohk cardano-node image to use
#  run - cardano-node option to run the node
# the rest are just cardano-node parameters
