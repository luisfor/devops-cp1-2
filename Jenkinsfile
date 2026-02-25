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
                sh 'python3 -m pytest test/unit --junitxml=test-reports/unit-results.xml'
            }
            post {
                always {
                    junit 'test-reports/unit-results.xml'
                }
            }
        }

        stage('Rest') {
            steps {
                echo "=== EJECUTANDO PRUEBAS DE INTEGRACIÓN ==="
                sh './run_rest.sh'
            }
            post {
                always {
                    junit 'test-reports/rest-results.xml'
                }
            }
        }

        stage('Static') {
            steps {
                echo "=== OBTENIENDO MÉTRICAS DE CÓDIGO ESTÁTICO (FLAKE8) ==="
                sh 'pip3 install flake8'
                sh 'flake8 app/ --format=default > flake8_report.txt || true'
            }
            post {
                always {
                    recordIssues(
                        tools: [flake8(pattern: 'flake8_report.txt')],
                        unstableTotalAll: 8,
                        failedTotalAll: 10
                    )
                }
            }
        }

        stage('Security Test') {
            steps {
                echo "=== OBTENIENDO MÉTRICAS DE SEGURIDAD (BANDIT) ==="
                sh 'pip3 install bandit'
                sh 'bandit -r app/ -f custom --msg-template "{abspath}:{line}: {severity}: {test_id}: {msg}" -o bandit_report.txt || true'
            }
            post {
                always {
                    recordIssues(
                        tools: [bandit(pattern: 'bandit_report.txt')],
                        unstableTotalAll: 2,
                        failedTotalAll: 4
                    )
                }
            }
        }
        
        stage('Coverage') {
            steps {
                echo "=== OBTENIENDO MÉTRICAS DE COBERTURA ==="
                sh 'pip3 install coverage'
                sh 'coverage run -m pytest test/unit'
                sh 'coverage xml -o coverage.xml'
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
