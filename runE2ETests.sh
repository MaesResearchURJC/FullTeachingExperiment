if [ -z "$1" ];
then
    echo "Use: runE2ETests.sh <BUG_TAG>"
    exit 1
fi

TESTS=(
    # 'UserRestTest'
    'FullTeachingTestE2EChat' 
    # 'FullTeachingTestE2EREST' 
    # 'FullTeachingTestE2EVideoSession' 
)

export BUG=$1
BUG_PATH="Bugs/$BUG"
PROJECT=full-teaching-experiment
PORT=5000

mkdir -p $BUG_PATH

cd full-teaching-experiment
git checkout -f demo
git clean -fdx
cd ..

echo "Starting FullTeaching using DockerCompose"


# INIT SERVER (SUT)
docker-compose up -d

EUS=$(docker inspect --format='{{ .NetworkSettings.Networks.elastest_elastest.IPAddress}}' fullteachingtest_eus_1)
export ET_EUS_API=http://$EUS:8040/eus/v1/
export ET_SUT_HOST=$(docker inspect --format='{{ .NetworkSettings.Networks.elastest_elastest.IPAddress}}' fullteachingtest_full-teaching_1)

# WAIT FOR SERVER STARTUP 
while ! curl --insecure --silent --output /dev/null "https://$ET_SUT_HOST:$PORT" ; do
   echo "-> FullTeaching is not ready in address '$ET_SUT_HOST' and port $PORT - RETRY ..."
   sleep 10
done

echo "FullTeaching UP in $ET_SUT_HOST:$PORT"

# WAIT FOR SERVER EUS
while ! curl --insecure --silent --output /dev/null $ET_EUS_API ; do
   echo "-> EUS is not ready in address '$ET_EUS_API' - RETRY ..."
   sleep 10
done

echo "EUS UP in $ET_EUS_API"



# RUN TESTs
for TEST in ${TESTS[@]};
do  
    echo "########## RUNNING TEST: $TEST"
    mkdir -p $BUG_PATH/$TEST/
    mvn -B -Dtest=$TEST test -f $PROJECT/pom.xml -DbrowserVersion=74 &> $BUG_PATH/$TEST/$TEST-TEST.log
    cp -r $PROJECT/target/surefire-reports/*$TEST.xml $BUG_PATH/$TEST/$TEST-surefire-report.xml
    docker-compose logs --no-color &> $BUG_PATH/$TEST/$TEST-SUT.log
done


# SHUTDOWN SERVER 
docker-compose down

# find . -type d -name UserRestTest -exec rm -rf {} \;
# find . -type d -name FullTeachingTestE2EChat -exec rm -rf {} \;
# find . -type d -name FullTeachingTestE2EREST -exec rm -rf {} \;
# find . -type d -name FullTeachingTestE2EVideoSession -exec rm -rf {} \;
# mvn -B -Dtest=$TEST test -DbrowserVersion=74

# PASOS:
# LANZAR EUS: docker run --rm --name eusmagico -e "ET_FILES_PATH_IN_HOST=/tmp" -e "ET_DATA_IN_HOST=/tmp" -p 8040:8040 -v /var/run/docker.sock:/var/run/docker.sock --network elastest_elastest -e "USE_TORM=true" elastest/eus
# LEVANTAR APP: docker-compose up -f
# CORRER TEST mvn -B -Dtest=$TEST test -DbrowserVersion=74