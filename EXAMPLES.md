# Ejemplos de Ejecución y Notificaciones

## 1. Ejecución Local del Pipeline

### Ejecución Completa

```bash
cd /ruta/del/proyecto
./run-pipeline.sh --full
```

**Salida esperada:**
```
========================================
EJECUTANDO PIPELINE COMPLETO
Build Number: local-1701432015
Directorio: /home/yohneps/Documentos/UNIR/DESPLIEGUES/Actividad3EIyEC/unir-cicd

========================================
Etapa: Construcción de Imágenes Docker
========================================
docker build -t calculator-app .
[... output de Docker build ...]
✓ Imágenes construidas exitosamente

========================================
Etapa: Pruebas Unitarias
========================================
docker run --name unit-tests ...
[... output de pytest ...]
✓ Pruebas unitarias completadas

========================================
Etapa: Pruebas de API
========================================
docker network create calc-test-api || true
[... output de pruebas ...]
✓ Pruebas de API completadas

========================================
Etapa: Pruebas E2E
========================================
docker network create calc-test-e2e || true
[... output de Cypress ...]
✓ Pruebas E2E completadas

========================================
Etapa: Despliegue a Staging
========================================
✓ Aplicación desplegada en staging

========================================
Etapa: Verificación de Salud
========================================
Verificando disponibilidad de API en: http://localhost:5000/calc/add/1/1
Intento 1 de 3...
✓ API respondiendo correctamente
Respuesta de la API:
{"result": 2}

========================================
Resultados de las Pruebas
========================================
Archivos generados:
-rw-r--r-- 1 user user  1234 Dec 1 12:00 unit_result.xml
-rw-r--r-- 1 user user   567 Dec 1 12:00 api_result.xml
-rw-r--r-- 1 user user   890 Dec 1 12:00 e2e_result.xml
-rw-r--r-- 1 user user  2345 Dec 1 12:00 coverage.xml
drwxr-xr-x 1 user user  4096 Dec 1 12:00 coverage/

========================================
PIPELINE COMPLETADO EXITOSAMENTE
========================================
```

### Ejecución de Etapas Específicas

```bash
# Solo construcción
./run-pipeline.sh --build

# Solo pruebas
./run-pipeline.sh --tests

# Solo pruebas unitarias
./run-pipeline.sh --unit

# Solo pruebas de API
./run-pipeline.sh --api

# Solo pruebas E2E
./run-pipeline.sh --e2e

# Solo deploy
./run-pipeline.sh --deploy

# Limpieza
./run-pipeline.sh --clean
```

---

## 2. Notificación por Email - Escenarios

### Escenario A: Pipeline Exitoso ✅

**Estado**: SUCCESS

**Email enviado**: NO ❌ (Solo se envía si falla)

**Acciones automáticas:**
- Reporte de cobertura publicado
- Resultados XML archivados
- Contenedores detenidos correctamente

---

### Escenario B: Pipeline con Advertencia ⚠️

**Estado**: UNSTABLE

**Email enviado**: SÍ ✅

```
To: devops@example.com
Subject: ⚠️ Pipeline Inestable - calculator-cicd #42

From: jenkins@example.com

Asunto: Pipeline tests not successful

Cuerpo:
El pipeline ha completado con resultados inestables.

Trabajo: calculator-cicd
Ejecución: 42
Estado: UNSTABLE

Detalles en: http://jenkins.example.com/job/calculator-cicd/42/
```

---

### Escenario C: Pipeline Fallido ❌

**Estado**: FAILURE

**Email enviado**: SÍ ✅

```html
To: devops@example.com
Subject: ❌ Pipeline Fallido - calculator-cicd #42

From: jenkins@example.com

Cuerpo (HTML):

┌─────────────────────────────────┐
│ ❌ Pipeline Fallido             │
├─────────────────────────────────┤
│ Trabajo: calculator-cicd        │
│ Número de Ejecución: #42        │
│ Estado: FAILURE                 │
│ Rama: origin/master             │
│ Commit: abc123def456789         │
│ Detalles: [LINK]                │
│ Logs: [LINK]                    │
└─────────────────────────────────┘
```

---

## 3. Casos de Fallo Comunes

### Caso 1: Fallo en Pruebas Unitarias

**Build**: #5  
**Estado**: FAILURE  
**Causa**: Una prueba unitaria no pasa

```
========================================
Etapa: Pruebas Unitarias
========================================
FAILED tests/unit/calc_test.py::test_add - AssertionError

Email enviado a: devops@example.com
Asunto: ❌ Pipeline Fallido - calculator-cicd #5
```

**Información en email:**
- Job: calculator-cicd
- Build: #5
- Rama: master
- Commit: abc123
- Enlace: http://jenkins.../job/calculator-cicd/5/
- Logs: http://jenkins.../job/calculator-cicd/5/console

---

### Caso 2: Fallo en Pruebas de API

**Build**: #7  
**Estado**: FAILURE  
**Causa**: API no responde en el tiempo esperado

```
========================================
Etapa: Pruebas de API
========================================
ERROR: Connection refused to http://apiserver:5000/

Email enviado a: devops@example.com
Asunto: ❌ Pipeline Fallido - calculator-cicd #7
```

---

### Caso 3: Fallo en Health Check

**Build**: #9  
**Estado**: FAILURE  
**Causa**: Health check falló después de 3 reintentos

```
========================================
Etapa: Verificación de Salud
========================================
Intento 1 de 3...
[timeout]
Intento 2 de 3...
[timeout]
Intento 3 de 3...
[timeout]

✗ API no respondió después de 3 intentos

Email enviado a: devops@example.com
Asunto: ❌ Pipeline Fallido - calculator-cicd #9
```

---

## 4. Configuración de Email para Pruebas

### Enviar email de prueba manualmente

Agregar esta etapa al Jenkinsfile:

```groovy
stage('Test Email') {
    steps {
        script {
            emailext(
                subject: "TEST - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Este es un email de prueba desde Jenkins",
                to: "${NOTIFY_EMAIL}"
            )
        }
    }
}
```

### Verificar logs de email en Jenkins

```
Manage Jenkins → System Log → All
```

Buscar:
- `EmailExtension`
- `SMTP`
- `MailSender`

---

## 5. Estructura de Reportes Generados

### Reporte XML (unit_result.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="pytest" errors="0" failures="0" skipped="0" tests="5" time="2.345">
    <testcase classname="test.unit.calc_test" name="test_add" time="0.123"/>
    <testcase classname="test.unit.calc_test" name="test_subtract" time="0.456"/>
    <testcase classname="test.unit.util_test" name="test_format" time="0.789"/>
  </testsuite>
</testsuites>
```

### Reporte de Cobertura (coverage/index.html)

Se genera automáticamente y está disponible en:

```
Jenkins → Build #42 → Coverage Report → index.html
```

Contiene:
- Cobertura por archivo
- Líneas cubiertas vs no cubiertas
- Estadísticas generales

---

## 6. Flujo de Notificación Completo

### Ejecución que termina en FAILURE

```
1. Developer hace git push
   ↓
2. Jenkins detecta cambios (webhook o polling)
   ↓
3. Jenkins inicia build #42
   ↓
4. Etapas ejecutadas:
   ├─ Checkout ✓
   ├─ Build ✓
   ├─ Unit Tests ✓
   ├─ API Tests ✗ (Fallo aquí)
   └─ [Resto cancelado]
   ↓
5. Post-actions (siempre):
   ├─ Limpieza Docker
   └─ Archivado de resultados
   ↓
6. Post-actions (por estado):
   ├─ failure:
   │  ├─ Composición del email
   │  ├─ Envío a NOTIFY_EMAIL
   │  └─ Registro en logs
   │
   └─ always:
      └─ Limpieza de workspace
   ↓
7. Email recibido en: devops@example.com
   ├─ Asunto: ❌ Pipeline Fallido - calculator-cicd #42
   ├─ De: jenkins@example.com
   ├─ Body:
   │  ├─ Job: calculator-cicd
   │  ├─ Build: #42
   │  ├─ Rama: master
   │  ├─ Commit: abc123
   │  └─ Links
   │
   └─ [Email HTML formateado]
```

---

## 7. Configuración de Credenciales en Jenkins

### Crear Credenciales SMTP

**En Jenkins:**

1. **Manage Jenkins** → **Credentials**
2. **System** → **Global credentials**
3. **Add Credentials**

```
Kind: Username with password
Username: [tu_usuario_smtp]
Password: [tu_contraseña_smtp]
ID: smtp-credentials
Description: SMTP Credentials for Email notifications
```

### Usar en Jenkinsfile

```groovy
withCredentials([usernamePassword(
    credentialsId: 'smtp-credentials',
    usernameVariable: 'SMTP_USER',
    passwordVariable: 'SMTP_PASS'
)]) {
    // Las credenciales están disponibles como:
    // ${SMTP_USER} y ${SMTP_PASS}
}
```

---

## 8. Variables Disponibles en Email

```groovy
// Información del build
${BUILD_NUMBER}          // 42
${JOB_NAME}             // calculator-cicd
${BUILD_URL}            // http://jenkins.../job/calculator-cicd/42/
${BUILD_ID}             // 2025-12-01_12-00-42

// Información de Git
${GIT_BRANCH}           // origin/master
${GIT_COMMIT}           // abc123def456...
${GIT_COMMIT_MSG}       // "Fix: API response time"

// Información del build
${BUILD_LOG}            // Log completo
${BUILD_LOG_EXCERPT}    // Primeras 50 líneas
${CHANGES}              // Cambios incluidos

// Información del sistema
${JENKINS_URL}          // http://jenkins.example.com/
${WORKSPACE}            // /var/jenkins/workspace/...
${NODE_NAME}            // docker-agent-01
```

---

## 9. Templates de Email Personalizados

### Email minimalista

```groovy
emailext(
    subject: "Build ${env.BUILD_NUMBER}: ${currentBuild.result}",
    body: """
        Job: ${env.JOB_NAME}
        Build: ${env.BUILD_NUMBER}
        Details: ${env.BUILD_URL}
    """,
    to: "${NOTIFY_EMAIL}"
)
```

### Email completo con HTML

```groovy
emailext(
    subject: "❌ ${env.JOB_NAME} #${env.BUILD_NUMBER} - FAILED",
    body: """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial; background: #f5f5f5; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; }
                .header { background: #d9534f; color: white; padding: 15px; }
                .section { margin: 15px 0; padding: 10px; border-left: 4px solid #d9534f; }
                .label { font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header"><h2>Pipeline Failed</h2></div>
                <div class="section">
                    <div class="label">Job:</div> ${env.JOB_NAME}
                </div>
                <div class="section">
                    <div class="label">Build:</div> #${env.BUILD_NUMBER}
                </div>
                <div class="section">
                    <div class="label">Branch:</div> ${env.GIT_BRANCH}
                </div>
                <div class="section">
                    <div class="label">Details:</div>
                    <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                </div>
            </div>
        </body>
        </html>
    """,
    to: "${NOTIFY_EMAIL}",
    mimeType: 'text/html'
)
```

---

## 10. Testing Local sin Jenkins

```bash
# Ejecutar todo localmente
./run-pipeline.sh --full

# Ver resultados
ls -la results/
cat results/unit_result.xml
cat results/api_result.xml

# Abrir reporte de cobertura
open results/coverage/index.html  # macOS
xdg-open results/coverage/index.html  # Linux
start results/coverage/index.html  # Windows
```

---

**Última actualización**: Diciembre 2025  
**Versión**: 1.0
