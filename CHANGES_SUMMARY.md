# 📋 Resumen de Cambios - Pipeline CICD para Jenkins

**Fecha**: 1 de Diciembre de 2025  
**Proyecto**: unir-cicd (Calculadora)  
**Versión**: 1.0

---

## 🎯 Objetivos Logrados

✅ Nuevas etapas para ejecutar las pruebas de API y las pruebas de E2E  
✅ Archivado de los archivos XML de las pruebas  
✅ Presentación de los informes de pruebas de API y E2E  
✅ Notificación por correo indicando fallo (con nombre del trabajo y número de ejecución)  
✅ Pipeline en Jenkins por medio de Docker en agente local  
✅ Descarga automática del repositorio por Git  
✅ Arranque automático de la aplicación  

---

## 📁 Archivos Creados

### 1. **Jenkinsfile.cicd.groovy** (10 KB)
Pipeline principal de Jenkins con todas las etapas.

**Características:**
- Checkout automático del repositorio
- Build de imágenes Docker
- Ejecución de pruebas unitarias, API y E2E
- Archivado de resultados XML
- Publicación de reportes (Cobertura + JUnit)
- Despliegue automático en Staging
- Health check del servidor
- **Notificaciones por email SOLO si falla**
  - Incluye nombre del trabajo: `${JOB_NAME}`
  - Incluye número de ejecución: `${BUILD_NUMBER}`
  - Incluye datos adicionales: rama, commit, enlaces

**Etapas:**
1. Checkout (Git Clone)
2. Build (Docker)
3. Unit Tests (pytest + cobertura)
4. API Tests (REST)
5. E2E Tests (Cypress)
6. Start Application (Deploy)
7. Health Check (Verificación)

---

### 2. **run-pipeline.sh** (6.1 KB)
Script auxiliar para ejecutar el pipeline localmente sin Jenkins.

**Características:**
- Ejecución de etapas individuales o completas
- Colores en output para mejor legibilidad
- Manejo de errores
- Limpieza automática de recursos
- Ayuda integrada

**Uso:**
```bash
./run-pipeline.sh --full       # Ejecución completa
./run-pipeline.sh --tests      # Solo pruebas
./run-pipeline.sh --build      # Solo build
./run-pipeline.sh --clean      # Limpiar
```

---

### 3. **JENKINS_SETUP.md** (7.8 KB)
Guía completa de configuración de Jenkins.

**Contiene:**
- Requisitos previos
- Descripción de cada etapa
- Características de archivado y reportes
- Configuración paso a paso
- Variables de entorno
- Targets del Makefile
- Solución de problemas comunes

---

### 4. **JENKINS_CONFIG.md** (8.3 KB)
Configuración detallada de variables y credenciales.

**Contiene:**
- Variables de email
- Configuración SMTP
- Credenciales Jenkins
- Tokens disponibles
- Ejemplos de emails personalizados
- Troubleshooting

---

### 5. **PIPELINE_SUMMARY.md** (9 KB)
Resumen ejecutivo del pipeline.

**Contiene:**
- Quick start
- Etapas del pipeline (diagrama)
- Notificaciones por email
- Configuración importante
- Checklist pre-producción

---

### 6. **EXAMPLES.md** (12 KB)
Ejemplos prácticos y casos de uso.

**Contiene:**
- Ejemplos de ejecución local
- Escenarios de notificación
- Casos de fallo comunes
- Estructura de reportes
- Flujos completos
- Templates de email

---

### 7. **JENKINS_PIPELINE_CONFIG.sh.example** (1.2 KB)
Archivo de configuración de variables.

**Contiene:**
- Todas las variables configurables
- Explicaciones de cada variable
- Valores por defecto
- Instrucciones de uso

---

## 📝 Archivos Modificados

### **Makefile** (4.7 KB)

**Cambios:**
1. Añadido target `setup`: Crea directorio de resultados
2. Mejorado `build`: Ahora depende de `setup`
3. Mejorado `test-unit`: Mensaje de finalización
4. Mejorado `test-api`: 
   - Espera 3 segundos después de iniciar servidor
   - Mejor manejo de copias de archivos
   - Mensaje de finalización
5. Mejorado `test-e2e`:
   - Espera 2 segundos después de iniciar servidor
   - Mejor manejo de copias de archivos
   - Mensaje de finalización
6. Añadido target `clean-docker`: Limpia recursos Docker
7. Añadido target `clean-results`: Limpia resultados
8. Añadido target `clean`: Limpia todo

**Nuevo workflow:**
```bash
make build         # Crea imágenes
make test-unit     # Pruebas unitarias
make test-api      # Pruebas API
make test-e2e      # Pruebas E2E
make deploy-stage  # Deploy
make clean         # Limpiar todo
```

---

## 🔧 Configuración Requerida en Jenkins

### 1. **Plugin requerido**
- Email Extension Plugin

### 2. **Sistema → Extended Email Notification**
```
SMTP Server: mail.example.com
SMTP Port: 587
Use TLS: ✓
Default From: jenkins@example.com
```

### 3. **Agente requerido**
- Label: `docker`
- Docker: Instalado y accesible

### 4. **Variable a personalizar**
En `Jenkinsfile.cicd.groovy` línea ~22:
```groovy
NOTIFY_EMAIL = "tu_email@ejemplo.com"  // CAMBIAR AQUÍ
```

---

## 📊 Flujo de Ejecución del Pipeline

```
Git Push / Webhook
    ↓
Jenkins detecta cambios
    ↓
Inicia Build (Docker Agent)
    ↓
├─ Checkout (Git Clone)
│   ↓
├─ Build (Docker Images)
│   ↓
├─ Unit Tests (pytest)
│   ├─ Archiva: unit_result.xml
│   └─ Archiva: coverage.xml
│   ↓
├─ API Tests (pytest REST)
│   └─ Archiva: api_result.xml
│   ↓
├─ E2E Tests (Cypress)
│   └─ Archiva: e2e_result.xml
│   ↓
├─ Start Application (Deploy)
│   └─ Espera 5 segundos
│   ↓
└─ Health Check
    └─ Verifica 3 veces con reintentos
    ↓
POST Actions
├─ SUCCESS: Publica reportes
├─ UNSTABLE: Email de advertencia ⚠️
├─ FAILURE: Email de error ❌
│   ├─ Incluye: Job Name
│   ├─ Incluye: Build Number
│   ├─ Incluye: Rama
│   ├─ Incluye: Commit
│   └─ Incluye: Links
└─ ALWAYS: Limpieza Docker
```

---

## 📧 Política de Notificaciones por Email

### ✅ Cuando se envía

- **FAILURE**: Pipeline falla en cualquier etapa
- **UNSTABLE**: Pipeline completa pero con advertencias

### ❌ Cuando NO se envía

- **SUCCESS**: Pipeline completa exitosamente

### 📬 Contenido del Email (en caso de fallo)

```
Asunto: ❌ Pipeline Fallido - [JOB_NAME] #[BUILD_NUMBER]
De: jenkins@example.com
Para: devops@example.com

Cuerpo (HTML formateado):
├─ Trabajo: calculator-cicd
├─ Número de Ejecución: #42
├─ Estado: FAILURE
├─ Rama: origin/master
├─ Commit: abc123def456
├─ URL del Build: [LINK]
└─ URL de Logs: [LINK]
```

---

## 📦 Resultados Archivados

Cada ejecución genera archivos archivados automáticamente:

```
results/
├── unit_result.xml          # JUnit - Pruebas unitarias
├── api_result.xml           # JUnit - Pruebas API
├── e2e_result.xml           # JUnit - Pruebas E2E
├── coverage.xml             # Cobertura XML
└── coverage/                # Reporte HTML
    ├── index.html           # Página principal
    └── [archivos]           # Detalles de cobertura
```

### Acceso en Jenkins

- **Cobertura HTML**: Build → Coverage Report → index.html
- **Pruebas JUnit**: Build → Test Result
- **Artifacts**: Build → Build Artifacts

---

## 🧪 Cómo Usar Localmente

### Ejecución completa

```bash
cd /ruta/del/proyecto
./run-pipeline.sh --full
```

### Etapas específicas

```bash
./run-pipeline.sh --build      # Solo construcción
./run-pipeline.sh --tests      # Solo pruebas
./run-pipeline.sh --unit       # Solo unitarias
./run-pipeline.sh --api        # Solo API
./run-pipeline.sh --e2e        # Solo E2E
./run-pipeline.sh --deploy     # Solo deploy
./run-pipeline.sh --clean      # Limpiar
```

---

## ✅ Checklist de Configuración

- [ ] Jenkins instalado
- [ ] Plugin Email Extension instalado
- [ ] SMTP configurado (Manage Jenkins → System)
- [ ] Agente Docker disponible (label: `docker`)
- [ ] Repositorio Git accesible
- [ ] `NOTIFY_EMAIL` actualizada en Jenkinsfile
- [ ] Credenciales SMTP configuradas (si aplica)
- [ ] Pruebas locales exitosas: `./run-pipeline.sh --full`
- [ ] Build manual en Jenkins verificado
- [ ] Email de fallo recibido correctamente

---

## 🐛 Troubleshooting Rápido

### Email no se envía
1. Verificar SMTP configurado: **Manage Jenkins → System**
2. Ver logs: **Manage Jenkins → System Log**
3. Búsqueda: "EmailExtension" o "SMTP"

### Pruebas fallan
1. Ejecutar localmente: `./run-pipeline.sh --tests`
2. Ver logs de contenedores: `docker logs unit-tests`
3. Verificar puerto API: `curl http://localhost:5000/`

### Docker network exists
- El Makefile lo maneja automáticamente con `|| true`
- Si persiste: `docker network prune`

---

## 📚 Documentación

| Archivo | Propósito |
|---------|-----------|
| `JENKINS_SETUP.md` | Guía de configuración |
| `JENKINS_CONFIG.md` | Variables y credenciales |
| `PIPELINE_SUMMARY.md` | Resumen ejecutivo |
| `EXAMPLES.md` | Ejemplos prácticos |
| `JENKINS_PIPELINE_CONFIG.sh.example` | Variables configurables |

---

## 🚀 Próximos Pasos

1. **Instalar plugin Email Extension** en Jenkins
2. **Configurar SMTP** en Jenkins System
3. **Editar Jenkinsfile** con tu email
4. **Crear Job** en Jenkins apuntando a `Jenkinsfile.cicd.groovy`
5. **Probar localmente** con `./run-pipeline.sh --full`
6. **Ejecutar primer build** en Jenkins

---

## 📞 Soporte

Para dudas o problemas:
1. Revisar la documentación apropiada (ver tabla anterior)
2. Ejecutar `./run-pipeline.sh --full` localmente
3. Revisar logs: **Jenkins → Build → Console Output**
4. Buscar en Sistema Log: **Manage Jenkins → System Log**

---

## 📝 Notas Importantes

- ⚠️ **Email SOLO se envía si falla** el pipeline
- ✅ **Reportes se generan siempre** (exitoso o fallido)
- 🔄 **Limpieza automática** de recursos Docker
- 📊 **Cobertura HTML interactivo** disponible
- 🔐 **Usa credenciales Jenkins** para SMTP

---

## 🎓 Capacitación

Para aprender más sobre el pipeline:
1. Leer `JENKINS_SETUP.md` para entender la configuración
2. Leer `EXAMPLES.md` para ver casos prácticos
3. Ejecutar `./run-pipeline.sh --help` para opciones
4. Revisar `Jenkinsfile.cicd.groovy` para detalles técnicos

---

**Creado por**: DevOps Team  
**Última actualización**: 1 de Diciembre de 2025  
**Versión**: 1.0  
**Estado**: ✅ Listo para Producción
