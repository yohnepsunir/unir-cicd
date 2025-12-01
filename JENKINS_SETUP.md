# Configuración de Jenkins Pipeline CICD

## Descripción General

Este documento describe cómo configurar y utilizar el pipeline de Jenkins (`Jenkinsfile.cicd.groovy`) para ejecutar las pruebas de API, E2E y desplegar la aplicación en ambiente de staging.

## Requisitos Previos

- Jenkins instalado y configurado
- Docker instalado en el agente de Jenkins
- Plugin de Jenkins: Email Extension Plugin
- Agente de Jenkins etiquetado como `docker` con Docker disponible
- Acceso al repositorio Git

## Características del Pipeline

### 1. **Etapas Principales**

#### Stage 1: Checkout
- Descarga el repositorio desde Git
- Ejecutado en agente Docker local

#### Stage 2: Build
- Construye las imágenes Docker:
  - `calculator-app`: Imagen de la aplicación Python
  - `calc-web`: Imagen del frontend web

#### Stage 3: Unit Tests
- Ejecuta pruebas unitarias con cobertura
- Genera reporte de cobertura en HTML
- Archiva archivos XML de resultados
- Publica resultados en interfaz de Jenkins

#### Stage 4: API Tests
- Inicia servidor de API en contenedor
- Ejecuta pruebas de API
- Archiva resultados XML
- Publica resultados en interfaz de Jenkins

#### Stage 5: E2E Tests
- Inicia servidor de API
- Inicia frontend web
- Ejecuta pruebas E2E con Cypress
- Archiva resultados XML
- Publica resultados en interfaz de Jenkins

#### Stage 6: Start Application
- Solo se ejecuta si las pruebas son exitosas
- Despliega los contenedores en ambiente de staging
- Espera 5 segundos para que los servicios estén listos

#### Stage 7: Health Check
- Verifica que la API esté respondiendo correctamente
- Realiza reintentos (3 intentos)
- Solo se ejecuta si el deploy fue exitoso

### 2. **Archivado de Resultados**

Los archivos XML de pruebas se archivan automáticamente:
- `results/unit_result.xml` - Resultados de pruebas unitarias
- `results/coverage.xml` - Reporte de cobertura
- `results/api_result.xml` - Resultados de pruebas de API
- `results/e2e_result.xml` - Resultados de pruebas E2E

### 3. **Reportes Publicados**

#### Reportes en Jenkins:
- **Reporte de Cobertura HTML**: Disponible en la sección "Coverage Report" del build
- **Reportes de Pruebas JUnit**: Mostrados en la pestaña "Test Result" del build

#### Reportes de Email (en caso de fallo):
- Incluye nombre del trabajo: `${JOB_NAME}`
- Incluye número de ejecución: `${BUILD_NUMBER}`
- Incluye enlace al build completo
- Incluye enlace a los logs

### 4. **Notificaciones por Email**

#### Fallo del Pipeline
Se envía email SOLO si el pipeline falla:
- **Destinatario**: `devops@example.com` (configurable)
- **Asunto**: `❌ Pipeline Fallido - [JOB_NAME] #[BUILD_NUMBER]`
- **Contenido**: 
  - Nombre del trabajo
  - Número de ejecución
  - Rama Git
  - Commit
  - Enlaces a detalles y logs

#### Pipeline Inestable
- **Asunto**: `⚠️ Pipeline Inestable - [JOB_NAME] #[BUILD_NUMBER]`

#### Pipeline Exitoso
- Se genera reporte de cobertura
- Limpieza de workspace (opcional)

## Configuración de Jenkins

### 1. Crear Nueva Tarea (Job)

1. En Jenkins, click en **New Item**
2. Nombre: `calculator-cicd`
3. Seleccionar: **Pipeline**
4. Click **OK**

### 2. Configurar Agente

```groovy
agent {
    label 'docker'
}
```

Asegúrate de que tienes un agente etiquetado como `docker` con Docker instalado.

### 3. Configurar Pipeline

En la sección **Pipeline**:
- **Definition**: Pipeline script from SCM
- **SCM**: Git
  - **Repository URL**: Tu URL del repositorio
  - **Branch**: `*/master` (o tu rama default)
- **Script Path**: `Jenkinsfile.cicd.groovy`

### 4. Configurar Email

1. En Jenkins: **Manage Jenkins** → **System**
2. Busca **Extended Email Notification**
3. Configura:
   - **SMTP Server**: Tu servidor SMTP
   - **Default From**: Tu email de Jenkins
   - **SMTP Port**: 587 o 25 (según tu servidor)

### 5. Credenciales para Email

Para usar credenciales en el plugin Email Extension:

1. **Manage Jenkins** → **Credentials**
2. Añade credenciales SMTP si es necesario
3. Actualiza el pipeline con tus credenciales

## Variables de Entorno

```groovy
APP_IMAGE = "calculator-app:${env.BUILD_NUMBER}"
WEB_IMAGE = "calc-web:${env.BUILD_NUMBER}"
TEST_RESULTS_DIR = "results"
API_RESULTS = "${TEST_RESULTS_DIR}/api_result.xml"
E2E_RESULTS = "${TEST_RESULTS_DIR}/e2e_result.xml"
UNIT_RESULTS = "${TEST_RESULTS_DIR}/unit_result.xml"
COVERAGE_RESULTS = "${TEST_RESULTS_DIR}/coverage.xml"
NOTIFY_EMAIL = "devops@example.com"  # ⚠️ MODIFICAR SEGÚN TU ENTORNO
```

### Para cambiar el email de notificación:
Edita el Jenkinsfile y modifica la variable `NOTIFY_EMAIL`:
```groovy
NOTIFY_EMAIL = "tu_email@ejemplo.com"
```

## Targets disponibles en Makefile

```bash
# Construcción
make build              # Construye imágenes Docker

# Pruebas
make test-unit         # Ejecuta pruebas unitarias
make test-api          # Ejecuta pruebas de API
make test-e2e          # Ejecuta pruebas E2E

# Despliegue
make deploy-stage      # Despliega en staging

# Limpieza
make clean-docker      # Limpia contenedores de Docker
make clean-results     # Limpia resultados de pruebas
make clean             # Limpia todo
```

## Ejecución Manual del Pipeline

Desde la línea de comandos (local):

```bash
# Construir
make build

# Ejecutar pruebas
make test-unit
make test-api
make test-e2e

# Desplegar
make deploy-stage

# Limpiar
make clean
```

## Estructura de Resultados

```
results/
├── unit_result.xml          # Pruebas unitarias
├── api_result.xml           # Pruebas API
├── e2e_result.xml           # Pruebas E2E
├── coverage.xml             # Cobertura de código
└── coverage/                # Reporte HTML de cobertura
    ├── index.html
    ├── status.json
    └── ...
```

## Flujo de Ejecución

```
1. Checkout (Git Clone)
   ↓
2. Build (Docker Build)
   ↓
3. Unit Tests (pytest)
   ├─ Archiva: unit_result.xml
   ├─ Archiva: coverage.xml
   └─ Publica: Reporte de Cobertura
   ↓
4. API Tests (pytest con servidor)
   ├─ Archiva: api_result.xml
   └─ Publica: Resultados JUnit
   ↓
5. E2E Tests (Cypress)
   ├─ Archiva: e2e_result.xml
   └─ Publica: Resultados JUnit
   ↓
6. Start Application (Si exitoso)
   ├─ Inicia API server
   ├─ Inicia Web server
   └─ Espera 5 segundos
   ↓
7. Health Check (Si exitoso)
   ├─ Verifica API (3 reintentos)
   └─ Confirma disponibilidad
   ↓
8. POST Actions
   ├─ (SUCCESS) → Publica reportes
   ├─ (UNSTABLE) → Email de advertencia
   ├─ (FAILURE) → Email de error detallado
   └─ (ALWAYS) → Limpieza de recursos Docker
```

## Problemas Comunes

### Error: "agent01" no disponible
**Solución**: Cambiar la etiqueta del agente en el Jenkinsfile:
```groovy
agent {
    label 'docker'  // Usa la etiqueta correcta de tu agente
}
```

### Email no se envía
**Verificar**:
1. Plugin Email Extension instalado: **Manage Jenkins** → **Manage Plugins**
2. SMTP configurado correctamente
3. Email válido en la variable `NOTIFY_EMAIL`

### Pruebas fallan por timeout
**Solución**: Aumentar el timeout en el Jenkinsfile:
```groovy
options {
    timeout(time: 3, unit: 'HOURS')  // Cambiar a 3 horas
}
```

### Docker: Network already exists
**Solución**: El Makefile ya lo maneja con `docker network create ... || true`

### No se generan reportes XML
**Verificar**:
1. Las pruebas tienen los marcadores: `@pytest.mark.unit`, `@pytest.mark.api`
2. Los contenedores copian correctamente los archivos
3. El directorio `results/` existe

## Mejoras Futuras

- [ ] Integración con SonarQube para análisis de código
- [ ] Despliegue automático a Kubernetes
- [ ] Notificaciones a Slack/Teams
- [ ] Pruebas de rendimiento
- [ ] Escaneo de vulnerabilidades
- [ ] Generación de reportes en PDF

## Contacto y Soporte

Para problemas o sugerencias, contacta al equipo de DevOps.

---

**Última actualización**: Diciembre 2025
**Versión**: 1.0
