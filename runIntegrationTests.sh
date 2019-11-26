if [ -z "$1" ];
then
    echo "Use: runIntegrationTests.sh <BUG_TAG>"
    exit 1
fi

TESTS=(
    # COMMENT
    'CommentControllerTest'
    # COURSE
    'CourseControllerTest'
    # ENTRY
    'EntryControllerTest'
    # FILE
    'FileControllerTest'
    # FILEGROUP
    'FileGroupControllerTest'
    # FORUM
    'ForumControllerTest'
    # SECURITY
    'AutorizationServiceUnitaryTest'
    'LoginControllerUnitaryTest'
    # SESSION
    'SessionControllerTest'
    # USER
    'UserControllerTest'
)

export BUG=$1
BUG_PATH="Bugs/$BUG"
PROJECT=full-teaching-experiment

if ! [ -d $BUG_PATH ]; then
    mkdir $BUG_PATH
fi

echo "Checkout to $BUG branch"

cd full-teaching-experiment
git clean -fdx
git checkout -f $BUG
rm -rf src/test/java/com/fullteaching/backend/e2e/
cp -f ../utils/application.properties src/main/resources/application.properties
cp -f ../utils/pom.xml pom.xml
cp ../utils/maven-exec.sh maven-exec.sh
cd ..

# CREATE A DOCKER VOLUME TO STORE AND RE-USE THE MAVEN PACKAGES
docker volume create --name maven-repo

# RUN TESTs
for TEST in ${TESTS[@]};
do  
    echo "########## RUNNING TEST: $TEST"
    mkdir $BUG_PATH/$TEST/
    # RUN TEST WITH MAVEN CONTAINER
    docker run --name $PROJECT-$TEST \
        -v maven-repo:/root/.m2 \
        -v $PWD/$PROJECT:/usr/$PROJECT \
        -w /usr/$PROJECT \
        -e TEST=$TEST \
        maven:3-jdk-8-slim ./maven-exec.sh
    # STORE LOGS AND REPORTS
    docker logs $PROJECT-$TEST &> $BUG_PATH/$TEST/$TEST-TEST.log
    cp -r $PROJECT/target/surefire-reports/*$TEST.xml $BUG_PATH/$TEST/$TEST-surefire-report.xml
    # STOP AND REMOVE DOCKER CONTAINER
    docker rm -f $PROJECT-$TEST
done