if [ -z "$1" ];
then
    echo "Use: runE2ETests.sh <BUG_TAG>"
    exit 1
fi

TESTS=(
    'UserRestTest'
    'FullTeachingTestE2EChat' 
    'FullTeachingTestE2EREST' 
    'FullTeachingTestE2EVideoSession' 
)

export BUG=$1
BUG_PATH="Bugs/$BUG"
PROJECT=full-teaching-experiment
PORT=5000

mkdir -p $BUG_PATH

cd full-teaching-experiment
git checkout -f demo
git clean -fdx
cp ../utils/maven-exec.sh maven-exec.sh
cd ..

echo "Starting FullTeaching using DockerCompose"

# CREATE A DOCKER VOLUME TO STORE AND RE-USE THE MAVEN PACKAGES
docker volume create --name maven-repo

# CREARE NETWORK
docker network create elastest_elastest

# INIT SERVER (SUT)
docker-compose up -d

EUS=$(docker inspect --format='{{ .NetworkSettings.Networks.elastest_elastest.IPAddress}}' fullteachingexperiment_eus_1)
export ET_EUS_API=http://$EUS:8040/eus/v1/
export ET_SUT_HOST=$(docker inspect --format='{{ .NetworkSettings.Networks.elastest_elastest.IPAddress}}' fullteachingexperiment_full-teaching_1)

# WAIT FOR SERVER STARTUP 
while ! curl --insecure --silent --output /dev/null "https://$ET_SUT_HOST:$PORT" ; do
   echo "-> FullTeaching is not ready in address '$ET_SUT_HOST' and port $PORT - RETRY ..."
   sleep 10
done

echo "FullTeaching UP in $ET_SUT_HOST:$PORT"

# WAIT FOR EUS 
while ! curl --insecure --silent --output /dev/null $ET_EUS_API ; do
   echo "-> EUS is not ready in address '$ET_EUS_API' - RETRY ..."
   sleep 10
done

echo "EUS UP in $ET_EUS_API"

echo "Waiting a bit more ... (240s)"
sleep 240

# RUN TESTs
for TEST in ${TESTS[@]};
do  
    echo "########## RUNNING TEST: $TEST"
    mkdir -p $BUG_PATH/$TEST/
    docker run --name $PROJECT-$TEST \
        -v maven-repo:/root/.m2 \
        -v $PWD/$PROJECT:/usr/$PROJECT \
        -w /usr/$PROJECT \
        -e ET_EUS_API=$ET_EUS_API\
        -e ET_SUT_HOST=$ET_SUT_HOST\
        -e TEST=$TEST \
        --network="elastest_elastest" \
        maven:3-jdk-8-slim \
        ./maven-exec.sh 
    # STORE LOGS AND REPORTS
    docker logs $PROJECT-$TEST &> $BUG_PATH/$TEST/$TEST-TEST.log
    cp -r $PROJECT/target/surefire-reports/*$TEST.xml $BUG_PATH/$TEST/$TEST-surefire-report.xml
    docker-compose logs --no-color &> $BUG_PATH/$TEST/$TEST-SUT.log
    # STOP AND REMOVE DOCKER CONTAINER
    docker rm -f $PROJECT-$TEST    
done


# SHUTDOWN SERVER 
docker-compose down