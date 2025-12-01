# Pipeline CICD para Jenkins - Calculadora

## 📋 Resumen Ejecutivo

Se ha configurado un pipeline de Jenkins completo para automatizar pruebas y despliegue de la aplicación Calculadora. El pipeline incluye:

- ✅ **Pruebas Unitarias** con cobertura
- ✅ **Pruebas de API** (REST)
- ✅ **Pruebas E2E** (Cypress)
- ✅ **Archivado de resultados** (XML)
- ✅ **Reportes HTML** (Cobertura)
- ✅ **Despliegue en Staging** (Docker)
- ✅ **Health Check** automático
- ✅ **Notificaciones por Email** (solo si falla)

---

## 📁 Archivos Creados/Modificados

### Nuevos Archivos

| Archivo | Descripción |
|---------|-------------|
| `Jenkinsfile.cicd.groovy` | Pipeline principal de Jenkins |
| `JENKINS_SETUP.md` | Guía completa de configuración |
| `JENKINS_CONFIG.md` | Configuración de variables y credenciales |
| `run-pipeline.sh` | Script auxiliar para ejecución local |

### Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `Makefile` | Nuevas etapas mejoradas + cleanup |

---

## 🚀 Quick Start

### Opción 1: Ejecución Local (sin Jenkins)

```bash
# Ejecución completa
./run-pipeline.sh --full

# O etapas específicas
./run-pipeline.sh --build
./run-pipeline.sh --tests
./run-pipeline.sh --deploy
./run-pipeline.sh --clean
```

### Opción 2: Configuración en Jenkins

1. **Crear nuevo Job en Jenkins**
   - Tipo: Pipeline
   - Nombre: `calculator-cicd`

2. **Configurar Pipeline**
   - Definition: Pipeline script from SCM
   - Repository: Tu URL de Git
   - Script Path: `Jenkinsfile.cicd.groovy`

3. **Configurar Email**
   - Instalar plugin: Email Extension
   - Configurar SMTP en: **Manage Jenkins → System**
   - Editar variable en Jenkinsfile: `NOTIFY_EMAIL = "tu_email@example.com"`

---

## 📊 Etapas del Pipeline

```
┌─────────────────────────────────────────────────────┐
│  Etapa 1: Checkout (Git Clone)                      │
├─────────────────────────────────────────────────────┤
│  Etapa 2: Build (Docker - Imágenes)                 │
├─────────────────────────────────────────────────────┤
│  Etapa 3: Unit Tests (pytest + cobertura)           │
│  └─ Archiva: unit_result.xml, coverage.xml          │
├─────────────────────────────────────────────────────┤
│  Etapa 4: API Tests (pytest REST)                   │
│  └─ Archiva: api_result.xml                         │
├─────────────────────────────────────────────────────┤
│  Etapa 5: E2E Tests (Cypress)                       │
│  └─ Archiva: e2e_result.xml                         │
├─────────────────────────────────────────────────────┤
│  Etapa 6: Start Application (Deploy)                │
├─────────────────────────────────────────────────────┤
│  Etapa 7: Health Check (Verificación)               │
└─────────────────────────────────────────────────────┘
         │
         ├─ SUCCESS: Publicar reportes ✅
         ├─ UNSTABLE: Email de advertencia ⚠️
         └─ FAILURE: Email de error ❌
            (Incluye: Nombre del Job + Build #)
```

---

## 📧 Notificaciones por Email

### ✅ Cuando se envía email

El email **SOLO se envía si el pipeline falla** (FAILURE o UNSTABLE).

### 📬 Contenido del Email

En caso de **FAILURE**, incluye:

```
❌ Pipeline Fallido - [JOB_NAME] #[BUILD_NUMBER]

Información:
- Trabajo: calculator-cicd
- Ejecución: #42
- Rama: master
- Commit: abc123def456
- Detalles: [LINK al build]
- Logs: [LINK a los logs]
```

### 🔧 Configuración del Email

1. Editar `Jenkinsfile.cicd.groovy`:

```groovy
NOTIFY_EMAIL = "tu_email@ejemplo.com"  // ← CAMBIAR AQUÍ
```

2. Configurar SMTP en Jenkins:
   - **Manage Jenkins** → **System**
   - **Extended Email Notification**
   - SMTP Server, puerto, credenciales

---

## 📦 Archivos Archivados

Los siguientes archivos se archivan automáticamente en cada ejecución:

```
results/
├── unit_result.xml          # Resultados pruebas unitarias
├── api_result.xml           # Resultados pruebas API
├── e2e_result.xml           # Resultados pruebas E2E
├── coverage.xml             # Reporte de cobertura
└── coverage/                # Reporte HTML de cobertura
    ├── index.html
    ├── status.json
    └── [archivos de cobertura]
```

### Acceso a Reportes en Jenkins

- **Cobertura**: Pestaña "Coverage Report" en el build
- **Pruebas**: Pestaña "Test Result" en el build
- **Artifacts**: Pestaña "Build Artifacts" en el build

---

## 🛠️ Targets Disponibles en Makefile

```bash
# Construcción
make build              # Construir imágenes Docker

# Pruebas
make test-unit         # Pruebas unitarias
make test-api          # Pruebas API
make test-e2e          # Pruebas E2E

# Despliegue
make deploy-stage      # Desplegar en staging

# Limpieza
make clean-docker      # Limpiar contenedores
make clean-results     # Limpiar resultados
make clean             # Limpiar todo
```

---

## 📋 Configuración de Agente Docker

Jenkins necesita un agente con etiqueta `docker`:

```groovy
agent {
    label 'docker'
}
```

**Requisitos del agente:**
- Docker instalado y corriendo
- Acceso a socket Docker
- Conexión de red a la máquina host

---

## 🔒 Credenciales Necesarias

Si usas credenciales SMTP seguras en Jenkins:

1. **Manage Jenkins** → **Credentials**
2. **Add Credentials**
3. Tipo: `Username with password`
4. ID: `smtp-credentials`

Luego en Jenkinsfile:
```groovy
withCredentials([usernamePassword(
    credentialsId: 'smtp-credentials',
    usernameVariable: 'SMTP_USER',
    passwordVariable: 'SMTP_PASS'
)]) { ... }
```

---

## ⚠️ Configuración Importante

### Email

```groovy
// En Jenkinsfile.cicd.groovy, línea ~22
NOTIFY_EMAIL = "devops@example.com"  // CAMBIAR POR TU EMAIL
```

### SMTP (en Jenkins System Config)

```
SMTP Server: mail.example.com
SMTP Port: 587
Use TLS: ✓
SMTP User: tu_usuario@example.com
SMTP Password: [tu_contraseña]
```

### Agente Docker

Verificar que el agente está etiquetado como `docker`:

```bash
# En el agente, verificar
docker ps
docker version
```

---

## 📝 Logs y Debugging

### Ver logs en Jenkins

1. Click en el build → **Console Output**
2. Buscar mensajes con prefijo:
   - `✓` = Exitoso
   - `✗` = Error
   - `⚠️` = Advertencia

### Troubleshooting

#### Email no se envía
```bash
# En Jenkins, ver logs del sistema
Manage Jenkins → System Log → All

# Buscar: "EmailExtension" o "SMTP"
```

#### Pruebas fallan
```bash
# Ver logs del contenedor
docker logs unit-tests
docker logs api-tests
docker logs e2e-tests
```

#### Docker: Network already exists
- El Makefile ya lo maneja con `|| true`
- Si persiste: `docker network prune`

---

## 🎯 Próximas Mejoras

- [ ] Integración SonarQube
- [ ] Análisis de seguridad (DevSecOps)
- [ ] Despliegue a Kubernetes
- [ ] Notificaciones a Slack/Teams
- [ ] Pruebas de rendimiento (JMeter)
- [ ] Generación de reportes en PDF
- [ ] Métricas en Grafana/Prometheus

---

## 📚 Documentación Completa

- **`JENKINS_SETUP.md`**: Guía de instalación y configuración
- **`JENKINS_CONFIG.md`**: Variables de entorno y credenciales
- **`run-pipeline.sh`**: Script de ejecución local con ejemplos

---

## ✅ Checklist Pre-Producción

- [ ] Email configurado en Jenkins
- [ ] SMTP servidor accesible
- [ ] Agente Docker etiquetado y disponible
- [ ] Repositorio Git accesible
- [ ] Plugin Email Extension instalado
- [ ] Variables `NOTIFY_EMAIL` actualizadas
- [ ] Pruebas locales exitosas con `./run-pipeline.sh --full`
- [ ] Build manual en Jenkins verificado

---

## 📞 Soporte

Para problemas:

1. Revisar **`JENKINS_SETUP.md`** (guía de configuración)
2. Revisar **`JENKINS_CONFIG.md`** (variables y credenciales)
3. Ejecutar `./run-pipeline.sh --full` localmente para debugging
4. Verificar logs en Jenkins: **Console Output**

---

## 📝 Notas Importantes

- El email **SOLO se envía si el pipeline falla**
- El reporte de cobertura es **HTML interactivo**
- Los resultados XML se preservan para análisis posteriores
- La limpieza de recursos Docker es **automática**
- El health check usa 3 reintentos antes de fallar

---

**Creado**: Diciembre 2025  
**Versión**: 1.0  
**Autor**: DevOps Team
