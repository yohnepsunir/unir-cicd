#!/bin/bash

###############################################################################
#
# Script de ejecución de pipeline local
# Ejecuta todas las etapas del pipeline sin necesidad de Jenkins
#
# Uso: ./run-pipeline.sh [opción]
#      ./run-pipeline.sh              # Ejecuta todo
#      ./run-pipeline.sh --build      # Solo build
#      ./run-pipeline.sh --tests      # Solo pruebas
#      ./run-pipeline.sh --full       # Build + Pruebas + Deploy
#      ./run-pipeline.sh --clean      # Limpia todo
#
###############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_NUMBER=${BUILD_NUMBER:-"local-$(date +%s)"}
RESULTS_DIR="results"

# Funciones
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_step() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

show_help() {
    cat << EOF
Uso: $(basename "$0") [OPCIÓN]

Opciones:
    --build         Solo construcción de imágenes
    --unit          Solo pruebas unitarias
    --api           Solo pruebas de API
    --e2e           Solo pruebas E2E
    --tests         Todas las pruebas (unit + api + e2e)
    --deploy        Deploy a staging
    --healthcheck   Verificar salud de la aplicación
    --full          Ejecución completa (build + tests + deploy + healthcheck)
    --clean         Limpiar todo (Docker + resultados)
    --help          Mostrar esta ayuda

Ejemplos:
    $(basename "$0") --build
    $(basename "$0") --tests
    $(basename "$0") --full
    $(basename "$0") --clean

EOF
}

# Etapas del pipeline
stage_build() {
    print_header "Etapa: Construcción de Imágenes Docker"
    cd "$SCRIPT_DIR"
    make build
    print_step "Imágenes construidas exitosamente"
}

stage_test_unit() {
    print_header "Etapa: Pruebas Unitarias"
    cd "$SCRIPT_DIR"
    make test-unit
    print_step "Pruebas unitarias completadas"
}

stage_test_api() {
    print_header "Etapa: Pruebas de API"
    cd "$SCRIPT_DIR"
    make test-api
    print_step "Pruebas de API completadas"
}

stage_test_e2e() {
    print_header "Etapa: Pruebas E2E"
    cd "$SCRIPT_DIR"
    make test-e2e
    print_step "Pruebas E2E completadas"
}

stage_deploy() {
    print_header "Etapa: Despliegue a Staging"
    cd "$SCRIPT_DIR"
    make deploy-stage
    print_step "Aplicación desplegada en staging"
    sleep 5
}

stage_healthcheck() {
    print_header "Etapa: Verificación de Salud"
    
    local max_attempts=3
    local attempt=1
    local api_url="http://localhost:5000/calc/add/1/1"
    
    echo "Verificando disponibilidad de API en: $api_url"
    
    while [ $attempt -le $max_attempts ]; do
        echo "Intento $attempt de $max_attempts..."
        
        if curl -s -f "$api_url" > /dev/null 2>&1; then
            print_step "API respondiendo correctamente"
            
            # Mostrar respuesta de prueba
            echo -e "${BLUE}Respuesta de la API:${NC}"
            curl -s "$api_url"
            echo ""
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            print_warning "API no disponible, reintentando en 3 segundos..."
            sleep 3
        fi
        
        ((attempt++))
    done
    
    print_error "API no respondió después de $max_attempts intentos"
    return 1
}

show_results() {
    print_header "Resultados de las Pruebas"
    
    if [ -d "$RESULTS_DIR" ]; then
        echo -e "${BLUE}Archivos generados:${NC}"
        ls -lah "$RESULTS_DIR"/ 2>/dev/null || echo "No hay archivos en resultados"
        
        # Mostrar resumen de XMLs si existen
        for xml_file in "$RESULTS_DIR"/*.xml; do
            if [ -f "$xml_file" ]; then
                filename=$(basename "$xml_file")
                echo ""
                echo -e "${BLUE}Contenido de $filename:${NC}"
                cat "$xml_file"
            fi
        done
    else
        print_warning "Directorio de resultados no encontrado"
    fi
}

cleanup() {
    print_header "Limpieza de Recursos"
    cd "$SCRIPT_DIR"
    make clean
    print_step "Limpieza completada"
}

# Ejecución completa
run_full() {
    print_header "EJECUTANDO PIPELINE COMPLETO"
    echo "Build Number: $BUILD_NUMBER"
    echo "Directorio: $SCRIPT_DIR"
    echo ""
    
    stage_build || { print_error "Build fallido"; exit 1; }
    echo ""
    
    stage_test_unit || { print_error "Pruebas unitarias fallaron"; exit 1; }
    echo ""
    
    stage_test_api || { print_warning "Pruebas de API fallaron"; }
    echo ""
    
    stage_test_e2e || { print_warning "Pruebas E2E fallaron"; }
    echo ""
    
    stage_deploy || { print_error "Deploy fallido"; exit 1; }
    echo ""
    
    stage_healthcheck || { print_warning "Healthcheck fallido"; }
    echo ""
    
    show_results
    
    print_header "PIPELINE COMPLETADO EXITOSAMENTE"
}

# Programa principal
main() {
    case "${1:-}" in
        --build)
            stage_build
            ;;
        --unit)
            stage_test_unit
            ;;
        --api)
            stage_test_api
            ;;
        --e2e)
            stage_test_e2e
            ;;
        --tests)
            print_header "EJECUTANDO TODAS LAS PRUEBAS"
            stage_test_unit && stage_test_api && stage_test_e2e
            show_results
            ;;
        --deploy)
            stage_deploy
            ;;
        --healthcheck)
            stage_healthcheck
            ;;
        --full)
            run_full
            ;;
        --clean)
            cleanup
            ;;
        --help|'-h')
            show_help
            ;;
        "")
            # Ejecución por defecto: todo
            run_full
            ;;
        *)
            print_error "Opción desconocida: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar
main "$@"
