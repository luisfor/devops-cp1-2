pipeline {
    agent none // Desactivamos el agente global porque asignaremos agentes por etapa

    stages {
        stage('Checkout Repo (En el Master)') {
            agent { label 'built-in' } // 'built-in' es el nombre moderno del Master en Jenkins
            steps {
                echo "=== INFORMACIÓN DEL NODO MASTER ==="
                sh 'whoami'
                sh 'hostname'
                sh 'echo ${WORKSPACE}'

                // 1. Descargamos el código de GitHub en el master
                checkout scm

                // 2. Empaquetamos todo el código fuente descargado para enviarlo al agente
                // 'stash' guarda los archivos de este workspace temporalmente
                stash includes: '**', name: 'codigo-fuente'
                
                // 3. Limpiamos el workspace del Master por buenas prácticas
                cleanWs()
            }
        }
        
        stage('Run Tests (En el Agente Mac)') {
            agent { label 'agente-mac' } // Aquí usamos la Etiqueta (Label) que le pusimos al agente nuevo
            steps {
                echo "=== INFORMACIÓN DEL NODO AGENTE ==="
                sh 'whoami'
                sh 'hostname'
                sh 'echo ${WORKSPACE}'

                // 1. Desempaquetamos el código que el master guardó previamente
                unstash 'codigo-fuente'

                // 2. Damos permisos y ejecutamos las pruebas
                sh 'chmod +x run_tests.sh'
                sh 'bash run_tests.sh'
            }
            post {
                always {
                    // 3. Pase lo que pase, limpiamos el workspace del Agente al terminar
                    cleanWs()
                }
            }
        }
    }
}
