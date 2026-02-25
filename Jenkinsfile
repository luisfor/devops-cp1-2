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
                echo "=== EJECUTANDO PRUEBAS UNITARIAS ==="
                sh 'pip3 install -r requirements.txt'
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'python3 -m pytest test/unit --junitxml=test-reports/unit-results.xml'
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
                sh 'pip3 install flake8'
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
                sh 'pip3 install bandit'
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
                echo "=== OBTENIENDO MÉTRICAS DE COBERTURA ==="
                sh 'pip3 install coverage'
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'python3 -m coverage run -m pytest test/unit'
                    sh 'python3 -m coverage xml -o coverage.xml'
                }
            }
            post {
                always {
                    cobertura coberturaReportFile: 'coverage.xml',
                              coberturaLineCoverageTargets: '85, 0, 95',
                              coberturaConditionalCoverageTargets: '80, 0, 90'
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
