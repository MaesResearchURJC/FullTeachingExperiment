ERRORS=(
    'demo'
    'bug1'
    'bug2'
    'bug3'
    'bug4'
    'bug5'
    'bug6'
    'bug7'
    'bug8'
    'bug9'
    'bug10'
    'bug11'
    'bug12'
    'bug13'
)

for ERROR in ${ERRORS[@]};
do  
	./runE2ETests.sh $ERROR
done