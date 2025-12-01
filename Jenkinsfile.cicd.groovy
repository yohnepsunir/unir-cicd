pipeline {
    agent {
        label 'docker'
    }

    options {
        timeout(time: 2, unit: 'HOURS')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    environment {
        // Variables de construcción
        APP_IMAGE = "calculator-app:${env.BUILD_NUMBER}"
        WEB_IMAGE = "calc-web:${env.BUILD_NUMBER}"
        TEST_RESULTS_DIR = "results"
        API_RESULTS = "${TEST_RESULTS_DIR}/api_result.xml"
        E2E_RESULTS = "${TEST_RESULTS_DIR}/e2e_result.xml"
        UNIT_RESULTS = "${TEST_RESULTS_DIR}/unit_result.xml"
        COVERAGE_RESULTS = "${TEST_RESULTS_DIR}/coverage.xml"
        // Variables para notificaciones
        NOTIFY_EMAIL = "yohn.parra@opensolution.co"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "========== Etapa: Checkout del repositorio =========="
                    checkout scm
                    echo "Repositorio descargado correctamente"
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    echo "========== Etapa: Construcción de imágenes Docker =========="
                    sh 'make build'
                    echo "Imágenes Docker construidas exitosamente"
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    echo "========== Etapa: Pruebas Unitarias =========="
                    sh 'make test-unit'
                    
                    // Archivar resultados
                    archiveArtifacts artifacts: "${UNIT_RESULTS},${COVERAGE_RESULTS}", 
                                   allowEmptyArchive: true
                    
                    // Publicar reporte de pruebas
                    junit testResults: "${UNIT_RESULTS}", 
                          allowEmptyResults: true,
                          skipPublishingChecks: true
                    
                    echo "Pruebas unitarias completadas"
                }
            }
        }

        stage('API Tests') {
            steps {
                script {
                    echo "========== Etapa: Pruebas de API =========="
                    try {
                        sh 'make test-api'
                        
                        // Archivar resultados XML
                        archiveArtifacts artifacts: "${API_RESULTS}", 
                                       allowEmptyArchive: true
                        
                        // Publicar reporte de pruebas
                        junit testResults: "${API_RESULTS}", 
                              allowEmptyResults: true,
                              skipPublishingChecks: true
                        
                        echo "Pruebas de API completadas"
                    } catch (Exception e) {
                        echo "Error en pruebas de API: ${e.message}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }

        stage('E2E Tests') {
            steps {
                script {
                    echo "========== Etapa: Pruebas End-to-End =========="
                    try {
                        sh 'make test-e2e'
                        
                        // Archivar resultados XML
                        archiveArtifacts artifacts: "${E2E_RESULTS}", 
                                       allowEmptyArchive: true
                        
                        // Publicar reporte de pruebas
                        junit testResults: "${E2E_RESULTS}", 
                              allowEmptyResults: true,
                              skipPublishingChecks: true
                        
                        echo "Pruebas E2E completadas"
                    } catch (Exception e) {
                        echo "Error en pruebas E2E: ${e.message}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }

        stage('Start Application') {
            when {
                expression { currentBuild.result == 'SUCCESS' || currentBuild.result == null }
            }
            steps {
                script {
                    echo "========== Etapa: Arranque de la aplicación =========="
                    sh 'make deploy-stage'
                    echo "Aplicación iniciada en ambiente de staging"
                    
                    // Esperar a que los servicios estén listos
                    sleep(time: 5, unit: 'SECONDS')
                }
            }
        }

        stage('Health Check') {
            when {
                expression { currentBuild.result == 'SUCCESS' || currentBuild.result == null }
            }
            steps {
                script {
                    echo "========== Etapa: Verificación de salud =========="
                    // Esperar a que el servidor esté disponible
                    retry(3) {
                        sh 'curl -f http://localhost:5000/calc/add/1/1 || exit 1'
                    }
                    echo "Aplicación respondiendo correctamente"
                }
            }
        }
    }

    post {
        always {
            script {
                echo "========== POST: Limpieza y consolidación =========="
                
                // Consolidar reportes de pruebas
                sh '''
                    if [ -d results ]; then
                        echo "Archivos de resultados encontrados:"
                        ls -la results/ || true
                    fi
                '''
                
                // Limpiar recursos de Docker
                sh '''
                    docker stop apiserver || true
                    docker stop calc-web || true
                    docker rm -f apiserver || true
                    docker rm -f calc-web || true
                    docker stop e2e-tests || true
                    docker rm -f e2e-tests || true
                    docker network rm calc-test-api || true
                    docker network rm calc-test-e2e || true
                '''
            }
        }

        success {
            script {
                echo "========== BUILD EXITOSO =========="
                // Publicar reportes HTML
                publishHTML([
                    reportDir: "${TEST_RESULTS_DIR}/coverage",
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report',
                    keepAll: true,
                    allowMissing: true
                ])
            }
        }

        unstable {
            script {
                echo "========== BUILD INESTABLE =========="
                emailext(
                    subject: "⚠️  Pipeline Inestable - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                        El pipeline ha completado con resultados inestables.
                        
                        Trabajo: ${env.JOB_NAME}
                        Ejecución: ${env.BUILD_NUMBER}
                        Estado: UNSTABLE
                        
                        Detalles en: ${env.BUILD_URL}
                    """,
                    to: "${NOTIFY_EMAIL}",
                    mimeType: 'text/html'
                )
            }
        }

        failure {
            script {
                echo "========== BUILD FALLIDO =========="
                emailext(
                    subject: "❌ Pipeline Fallido - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                        <!DOCTYPE html>
                        <html>
                        <head>
                            <style>
                                body { font-family: Arial, sans-serif; }
                                .container { background-color: #f5f5f5; padding: 20px; }
                                .header { color: #d9534f; font-size: 18px; font-weight: bold; }
                                .info { margin: 10px 0; }
                                .label { font-weight: bold; }
                            </style>
                        </head>
                        <body>
                            <div class="container">
                                <div class="header">❌ El Pipeline ha FALLADO</div>
                                <div class="info">
                                    <div class="label">Trabajo:</div> ${env.JOB_NAME}
                                </div>
                                <div class="info">
                                    <div class="label">Número de Ejecución:</div> ${env.BUILD_NUMBER}
                                </div>
                                <div class="info">
                                    <div class="label">Estado:</div> FAILURE
                                </div>
                                <div class="info">
                                    <div class="label">Rama:</div> ${env.GIT_BRANCH}
                                </div>
                                <div class="info">
                                    <div class="label">Commit:</div> ${env.GIT_COMMIT}
                                </div>
                                <div class="info">
                                    <div class="label">Detalles del Build:</div> 
                                    <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                                </div>
                                <div class="info">
                                    <div class="label">Logs:</div> 
                                    <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a>
                                </div>
                            </div>
                        </body>
                        </html>
                    """,
                    to: "${NOTIFY_EMAIL}",
                    mimeType: 'text/html'
                )
            }
        }
    }
}
