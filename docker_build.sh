set -ex
HERE=$(dirname $(readlink -f "$0"))
cd $HERE

TARGET=unidock2
REPOSITORY_NAME=unidock2

if [ "$CONTAINER_REGISTRY" == "" ]; then
    IMAGE_NAME=$REPOSITORY_NAME
else
    IMAGE_NAME=$CONTAINER_REGISTRY/$REPOSITORY_NAME
fi
docker build -t $IMAGE_NAME --target $TARGET .

if [ "$CONTAINER_REGISTRY" == "" ]; then
    echo
else
    docker push $IMAGE_NAME:latest
    echo "$IMAGE_NAME:latest" is pushed.
fi
