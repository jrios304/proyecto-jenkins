pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Verificando código fuente...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Instalando dependencias...'
                bat 'python -m pip install --no-cache-dir -r requirements.txt'
            }
        }

        stage('Test') {
            steps {
                echo 'Ejecutando pruebas...'
                bat 'python -m pytest tests/ -v --cov=app --cov-report=term-missing'
            }
        }

        stage('Kubernetes Validation') {
            steps {
                echo 'Validando manifiestos de Kubernetes...'
                bat 'type kubernetes\\deployment.yaml'
                bat 'type kubernetes\\service.yaml'
                bat 'type kubernetes\\hpa.yaml'
            }
        }

        stage('Deploy Simulation') {
            steps {
                bat '''
                    echo ========================================
                    echo   DESPLIEGUE SIMULADO EXITOSO
                    echo   App: proyecto-jenkins
                    echo   Build: %BUILD_NUMBER%
                    echo   Entorno: Produccion
                    echo   URL: http://localhost:8000
                    echo ========================================
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completado exitosamente!'
        }
        failure {
            echo 'Pipeline fallo. Revisa los logs.'
        }
    }
}