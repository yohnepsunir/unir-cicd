# Configuración de Variables de Entorno para Jenkins Pipeline

## Variables de Email

```groovy
// En Jenkinsfile.cicd.groovy, sección environment:

// Email de notificaciones en caso de fallo
NOTIFY_EMAIL = "devops@example.com"  // CAMBIAR POR TU EMAIL

// Emails adicionales (opcional)
NOTIFY_EMAIL_CC = ""
NOTIFY_EMAIL_BCC = ""
```

## Credenciales en Jenkins

Para usar credenciales seguros en Jenkins:

### 1. Crear Credenciales SMTP (si aplica)

```
Manage Jenkins → Credentials → System → Global credentials → Add Credentials
```

Seleccionar:
- **Kind**: Username with password
- **Username**: Tu usuario SMTP
- **Password**: Tu contraseña SMTP
- **ID**: `smtp-credentials`
- **Description**: SMTP Credentials for Email

### 2. Usar en el Jenkinsfile

```groovy
withCredentials([usernamePassword(
    credentialsId: 'smtp-credentials',
    usernameVariable: 'SMTP_USER',
    passwordVariable: 'SMTP_PASS'
)]) {
    // Tu código aquí
}
```

## Variables Disponibles del Build

Jenkins proporciona automáticamente estas variables:

```groovy
${env.BUILD_NUMBER}          // Número del build (1, 2, 3, ...)
${env.BUILD_ID}              // ID del build
${env.BUILD_URL}             // URL completa del build
${env.JOB_NAME}              // Nombre del job
${env.BRANCH_NAME}           // Rama Git (si applicable)
${env.GIT_BRANCH}            // Rama Git (formato: origin/master)
${env.GIT_COMMIT}            // Hash del commit
${env.GIT_COMMIT_MSG}        // Mensaje del commit
${env.WORKSPACE}             // Ruta del workspace
${currentBuild.result}       // Resultado actual (SUCCESS, FAILURE, etc.)
```

## Configuración de Email Extension Plugin

### Opción 1: Configuración Global (Recomendado)

1. **Manage Jenkins** → **System** → **Extended Email Notification**

```
SMTP Server: mail.example.com
SMTP Port: 587
Use SMTP Authentication: ✓
SMTP User: tu_usuario@example.com
SMTP Password: tu_contraseña
Use TLS: ✓
Default From: jenkins@example.com
Default Subject: $PROJECT_NAME - $BUILD_NUMBER
```

### Opción 2: Usando Credenciales Jenkins

```groovy
pipeline {
    environment {
        // Usar credenciales Jenkins
        SMTP_CREDENTIALS = credentials('smtp-credentials')
    }
    
    post {
        failure {
            emailext(
                subject: "Pipeline Fallido - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "El pipeline ha fallado",
                to: "${NOTIFY_EMAIL}"
            )
        }
    }
}
```

## Tokens disponibles en Email

En el cuerpo del email, puedes usar:

```
${BUILD_LOG}                 // Log completo del build
${BUILD_LOG_EXCERPT}         // Primeras líneas del log
${BUILD_LOG_REGEX_EXCERPT}   // Excerpto con regex personalizado
${BUILD_TIMESTAMP}           // Timestamp del build
${ENV, var="VARIABLE_NAME"}  // Valor de variable de entorno
${CHANGES}                   // Lista de cambios
${CHANGES_TRUNCATED}         // Cambios truncados
${JENKINS_URL}               // URL de Jenkins
${BUILD_URL}                 // URL del build
${PROJECT_NAME}              // Nombre del proyecto
${BUILD_NUMBER}              // Número del build
${BUILD_ID}                  // ID del build
${GIT_BRANCH}                // Rama Git
${GIT_COMMIT}                // Hash del commit
```

## Ejemplo: Email Personalizado

```groovy
post {
    failure {
        emailext(
            subject: "❌ FALLO - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """
                <!DOCTYPE html>
                <html>
                    <head>
                        <meta charset="UTF-8">
                        <style>
                            body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
                            .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; }
                            .header { background-color: #d9534f; color: white; padding: 15px; }
                            .section { margin: 15px 0; padding: 10px; border-left: 4px solid #d9534f; }
                            .label { font-weight: bold; }
                            code { background-color: #f5f5f5; padding: 5px; }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <div class="header">
                                <h2>❌ Pipeline Fallido</h2>
                            </div>
                            
                            <div class="section">
                                <div class="label">Trabajo:</div>
                                ${env.JOB_NAME}
                            </div>
                            
                            <div class="section">
                                <div class="label">Número de Ejecución:</div>
                                #${env.BUILD_NUMBER}
                            </div>
                            
                            <div class="section">
                                <div class="label">Rama:</div>
                                ${env.GIT_BRANCH}
                            </div>
                            
                            <div class="section">
                                <div class="label">Commit:</div>
                                <code>${env.GIT_COMMIT}</code>
                            </div>
                            
                            <div class="section">
                                <div class="label">Detalles:</div>
                                <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                            </div>
                            
                            <div class="section">
                                <div class="label">Logs:</div>
                                <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a>
                            </div>
                        </div>
                    </body>
                </html>
            """,
            to: "${NOTIFY_EMAIL}",
            mimeType: 'text/html',
            attachmentsPattern: 'results/**/*.xml',  // Adjuntar XMLs de pruebas
            attachLog: false
        )
    }
}
```

## Configuración de Archivos de Resultados

Los archivos se archivan automáticamente:

```groovy
archiveArtifacts(
    artifacts: 'results/*.xml,results/coverage/**',
    allowEmptyArchive: true,
    onlyIfSuccessful: false
)
```

## Variables Personalizadas

Puedes añadir tus propias variables en el Jenkinsfile:

```groovy
environment {
    // Información del proyecto
    PROJECT_NAME = "Calculator App"
    PROJECT_VERSION = "1.0.0"
    TEAM_NAME = "DevOps Team"
    
    // Configuración
    APP_IMAGE = "calculator-app:${env.BUILD_NUMBER}"
    WEB_IMAGE = "calc-web:${env.BUILD_NUMBER}"
    TEST_RESULTS_DIR = "results"
    
    // Notificaciones
    NOTIFY_EMAIL = "devops@example.com"
    SLACK_CHANNEL = "#jenkins-builds"  // Si usas Slack
}
```

## Limitar Notificaciones

Si quieres que solo ciertos usuarios reciban emails:

```groovy
post {
    failure {
        script {
            // Email solo si es rama master
            if (env.GIT_BRANCH == 'origin/master') {
                emailext(
                    subject: "❌ Pipeline Fallido - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: "...",
                    to: "${NOTIFY_EMAIL}"
                )
            }
        }
    }
}
```

## Prueba de Email

Para probar la configuración sin triggering el pipeline completo:

```groovy
stage('Test Email') {
    steps {
        script {
            emailext(
                subject: "TEST - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Este es un email de prueba",
                to: "${NOTIFY_EMAIL}"
            )
        }
    }
}
```

## Troubleshooting

### Email no se envía
- [ ] Verificar que el plugin Email Extension esté instalado
- [ ] Verificar que SMTP esté correctamente configurado
- [ ] Ver logs: **Manage Jenkins** → **System Log**
- [ ] Probar conectividad SMTP desde servidor Jenkins

### Email con caracteres extraños
- [ ] Usar `mimeType: 'text/html'` para HTML
- [ ] Verificar encoding UTF-8
- [ ] Usar `charset="UTF-8"` en HTML

### Adjuntos no se incluyen
- [ ] Verificar que los archivos existan
- [ ] Usar ruta relativa: `results/**/*.xml`
- [ ] Verificar permisos de lectura

---

**Última actualización**: Diciembre 2025
