set -ex
HERE=$(dirname $(readlink -f "$0"))
cd $HERE

REPOSITORY_NAME=unidock2

if [ "$CONTAINER_REGISTRY" == "" ]; then
    IMAGE_NAME=$REPOSITORY_NAME
else
    IMAGE_NAME=$CONTAINER_REGISTRY/$REPOSITORY_NAME
fi

set +e
nvidia-smi
if [ "$?" == "0" ]; then
    GPUOPTION="--gpus all"
else
    GPUOPTION=""
fi
set -e

# if you run using gpus add "--gpus all".
docker run \
    --rm \
    -e DISPLAY=:0 \
    -v ./:/workspace \
    $GPUOPTION \
    --shm-size=10.13gb \
    $IMAGE_NAME \
    unidock2 -r ./1iep_receptorH.pdb -l 1iep_ligand.sdf
