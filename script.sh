# ET_SUT_HOST=$(docker inspect --format='{{.NetworkSettings.Networks.elastest_elastest.IPAddress}}' fullteachingtest_full-teaching_1)
# curl --insecure --silent --output /dev/null "https://$ET_SUT_HOST:5000"
# echo $?

#  eus:
#    image: elastest/eus
#    environment:
#      - ET_FILES_PATH_IN_HOST=/tmp
#      - ET_DATA_IN_HOST=/tmp
#      - USE_TORM=true
#    ports:
#      - 8040:8040
#    networks:
#      - "elastest_elastest"
#    volumes: 
#      - /var/run/docker.sock:/var/run/docker.sock

EUS=$(docker inspect --format='{{ .NetworkSettings.Networks.elastest_elastest.IPAddress}}' fullteachingtest_eus_1)
export ET_EUS_API=http://$EUS:8040/eus/v1/
export ET_SUT_HOST=$(docker inspect --format='{{ .NetworkSettings.Networks.elastest_elastest.IPAddress}}' fullteachingtest_full-teaching_1)
export TEST=FullTeachingTestE2EVideoSession
PROJECT=full-teaching-experiment

cd full-teaching-experiment
git clean -fdx
cp ../utils/maven-exec.sh maven-exec.sh
cd ..

docker volume create --name maven-repo

docker run --rm --name $PROJECT-$TEST \
        -v maven-repo:/root/.m2 \
        -v $PWD/$PROJECT:/usr/$PROJECT \
        -w /usr/$PROJECT \
        -e ET_EUS_API=$ET_EUS_API\
        -e ET_SUT_HOST=$ET_SUT_HOST\
        -e TEST=$TEST -it \
        --network="elastest_elastest" \
        maven:3-jdk-8-slim bash \
        ./maven-exec.sh