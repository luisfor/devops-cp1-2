#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"
echo "=== INICIANDO APIS MOCK Y FLASK ==="

if [ ! -f "wiremock-standalone-3.12.0.jar" ]; then
    echo "Descargando Wiremock temporalmente para CI..."
    curl -sSL -o wiremock-standalone-3.12.0.jar https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.12.0/wiremock-standalone-3.12.0.jar
fi

# Wiremock usa --root-dir test/wiremock para encontrar test/wiremock/mappings/sqrt64.json
java -jar wiremock-standalone-3.12.0.jar --port 9090 --root-dir test/wiremock > wiremock.log 2>&1 &
WPID=$!

export FLASK_APP=app/api.py
python3 -m flask run -p 5001 > flask.log 2>&1 &
FPID=$!

sleep 4 # Dar tiempo a que arranquen

echo "=== INICIANDO PRUEBAS ==="
python3 -m pytest test/rest --junitxml=test-reports/rest-results.xml > test_output.txt 2>&1
RESULT=$?
cat test_output.txt
echo "=== PRUEBAS FINALIZADAS ==="

echo "=== APAGANDO SERVICIOS ==="
kill $WPID
kill $FPID

exit $RESULT
