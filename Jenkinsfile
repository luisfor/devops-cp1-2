pipeline {
    agent any

    stages {
        stage('Get Code') {
            steps {
                echo "=== OBTENIENDO CÓDIGO FUENTE ==="
                checkout scm
            }
        }
        
        stage('Unit') {
            steps {
                echo "=== EJECUTANDO PRUEBAS UNITARIAS Y RECOGIENDO COBERTURA ==="
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    // Combinamos ejecución de tests y recolección de cobertura para evitar duplicidad
                    sh 'python3 -m coverage run -m pytest test/unit --junitxml=test-reports/unit-results.xml'
                }
            }
            post {
                always {
                    junit testResults: 'test-reports/unit-results.xml', allowEmptyResults: true
                }
            }
        }

        stage('Rest') {
            steps {
                echo "=== EJECUTANDO PRUEBAS DE INTEGRACIÓN ==="
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh './run_rest.sh'
                }
            }
            post {
                always {
                    junit testResults: 'test-reports/rest-results.xml', allowEmptyResults: true
                }
            }
        }

        stage('Static') {
            steps {
                echo "=== OBTENIENDO MÉTRICAS DE CÓDIGO ESTÁTICO (FLAKE8) ==="
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'python3 -m flake8 app/ --format=default > flake8_report.txt || true'
                }
            }
            post {
                always {
                    recordIssues(
                        tools: [flake8(pattern: 'flake8_report.txt')],
                        qualityGates: [[threshold: 10, type: 'TOTAL', unstable: false], [threshold: 8, type: 'TOTAL', unstable: true]]
                    )
                }
            }
        }

        stage('Security Test') {
            steps {
                echo "=== OBTENIENDO MÉTRICAS DE SEGURIDAD (BANDIT) ==="
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'python3 -m bandit -r app/ -f custom --msg-template "{abspath}:{line}:1: {severity}: {test_id}: {msg}" -o bandit_report.txt || true'
                }
            }
            post {
                always {
                    recordIssues(
                        tools: [flake8(pattern: 'bandit_report.txt', id: 'bandit', name: 'Bandit')],
                        qualityGates: [[threshold: 4, type: 'TOTAL', unstable: false], [threshold: 2, type: 'TOTAL', unstable: true]]
                    )
                }
            }
        }
        
        stage('Coverage') {
            steps {
                echo "=== GENERANDO REPORTE DE COBERTURA ==="
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    // Solo generamos el XML a partir de los datos ya recogidos en la etapa Unit
                    sh 'python3 -m coverage xml -o coverage.xml'
                }
            }
            post {
                always {
                    recordCoverage(tools: [[parser: 'COBERTURA', pattern: 'coverage.xml']])
                }
            }
        }

        stage('Performance') {
            steps {
                echo "=== PRUEBAS DE CARGA JMETER ==="
                sh './run_performance.sh'
            }
            post {
                always {
                    perfReport errorFailedThreshold: 0,
                               errorUnstableThreshold: 0,
                               sourceDataFiles: 'test-reports/jmeter-results.jtl'
                }
            }
        }
    }
}
