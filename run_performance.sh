#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"
echo "=== INICIANDO FLASK PARA JMETER ==="

export FLASK_APP=app/api.py
python3 -m flask run -p 5001 > flask.log 2>&1 &
FPID=$!

sleep 4 # Dar tiempo a que arranque

echo "=== INICIANDO JMETER ==="
# Instalación de jmeter si no existe via brew
if ! command -v jmeter &> /dev/null
then
    echo "Instalando jmeter..."
    brew install jmeter
fi

# El test-plan pide 5 hilos y 40 peticiones a sumar y restar
# Hemos asumido que el test plan ya está configurado así en test/jmeter/flask.jmx 
# (como dice la guía, debe tener un test-plan así)

jmeter -n -t test/jmeter/flask.jmx -l test-reports/jmeter-results.jtl -e -o test-reports/jmeter-html-report
RESULT=$?

echo "=== APAGANDO SERVICIOS ==="
kill $FPID

exit $RESULT
