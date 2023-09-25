#!/bin/sh

totalTests=4
successfulTests=0
failedTests=0
failedTestsArray=()

keycloakBaseURL="https://abc.dev"
promBaseURL="https://abc.dev"
influxURL="https://abc.dev"
grafanaURL="https://abc.dev"

keycloakURL="$keycloakBaseURL/auth/realms/realmname"
promURL="$promBaseURL/api/v1/labels"

echo "Executing test for Keycloak...";
keycloakResponse=$(curl "$keycloakURL")

if [[ $keycloakResponse == *"public_key"* ]];
then
    successfulTests=$(( successfulTests + 1 ))
else
    failedTests=$(( failedTests + 1 ))
    failedTestsArray+=('Keycloak')
fi

echo "Executing test for Prometheus...";promResponse=$(curl "$promURL" )

if [[ $promResponse == *"success"* ]];
then
    successfulTests=$(( successfulTests + 1 ))
else
    failedTests=$(( failedTests + 1 ))
    failedTestsArray+=('Prometheus')
fi


echo "Executing test for InfluxDB...";
influxUrlStatus=$(curl --output /dev/null --silent --head --write-out '%{http_code}' "$influxURL" )
echo "$influxUrlStatus"

if [[ $influxUrlStatus == "200" ]];
then
    successfulTests=$(( successfulTests + 1 ))
else
    failedTests=$(( failedTests + 1 ))
    failedTestsArray+=('InfluxDB')
fi

echo "Executing test for Grafana...";
grafanaUrlStatus=$(curl --location --output /dev/null --silent --head --write-out '%{http_code}' "$grafanaURL" )
echo "$grafanaUrlStatus"

if [[ $grafanaUrlStatus == "200" ]];
then
    successfulTests=$(( successfulTests + 1 ))
else
    failedTests=$(( failedTests + 1 ))
    failedTestsArray+=('Grafana')
fi

echo "***************************"
echo "Total Tests: $totalTests"
echo "Successful: $successfulTests"
echo "Failed: $failedTests"
if (( $failedTests >= 1 ));
 then
    echo "---------------------------"
    echo "Failed Tests:"
    for str in ${failedTestsArray[@]}; do
        echo $str
        done
fi
echo "***************************"