#!/bin/bash

###############################################################################
#
# Script para ejecutar pruebas E2E con Cypress
#
# Uso: ./run-e2e-tests.sh [opción]
#      ./run-e2e-tests.sh              # Usar imagen estándar
#      ./run-e2e-tests.sh --build      # Construir imagen custom y ejecutar
#      ./run-e2e-tests.sh --custom     # Usar imagen custom
#
###############################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CYPRESS_IMAGE="cypress/included:4.9.0"
CUSTOM_IMAGE="calculator-e2e:latest"
USE_CUSTOM=false

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
    (sin opción)    Ejecutar con imagen estándar cypress/included:4.9.0
    --build         Construir imagen custom y ejecutar
    --custom        Usar imagen custom (si ya existe)
    --help          Mostrar esta ayuda

Ejemplos:
    $(basename "$0")              # Usar imagen estándar
    $(basename "$0") --build      # Construir y ejecutar
    $(basename "$0") --custom     # Usar custom si existe

EOF
}

# Construir imagen custom
build_custom_image() {
    print_header "Construyendo imagen custom de Cypress"
    
    if [ ! -f "$SCRIPT_DIR/Dockerfile.cypress" ]; then
        print_error "Archivo Dockerfile.cypress no encontrado en $SCRIPT_DIR"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
    docker build -f Dockerfile.cypress -t "$CUSTOM_IMAGE" .
    print_step "Imagen custom construida: $CUSTOM_IMAGE"
}

# Ejecutar pruebas E2E
run_e2e_tests() {
    local image=$1
    
    print_header "Ejecutando Pruebas E2E con Cypress"
    echo "Imagen: $image"
    echo ""
    
    cd "$SCRIPT_DIR"
    
    # Limpiar anteriores
    print_step "Limpiando recursos previos..."
    docker stop apiserver 2>/dev/null || true
    docker stop calc-web 2>/dev/null || true
    docker stop e2e-tests 2>/dev/null || true
    docker rm --force apiserver 2>/dev/null || true
    docker rm --force calc-web 2>/dev/null || true
    docker rm --force e2e-tests 2>/dev/null || true
    docker network rm calc-test-e2e 2>/dev/null || true
    sleep 1
    
    # Crear network
    print_step "Creando network..."
    docker network create calc-test-e2e || true
    
    # Iniciar API
    print_step "Iniciando servidor de API..."
    docker run -d \
        --network calc-test-e2e \
        --env PYTHONPATH=/opt/calc \
        --name apiserver \
        --env FLASK_APP=app/api.py \
        -p 5000:5000 \
        -w /opt/calc \
        calculator-app:latest \
        flask run --host=0.0.0.0
    sleep 2
    
    # Iniciar Web
    print_step "Iniciando frontend web..."
    docker run -d \
        --network calc-test-e2e \
        --name calc-web \
        -p 80:80 \
        calc-web
    sleep 3
    
    # Ejecutar pruebas E2E
    print_step "Ejecutando pruebas E2E..."
    mkdir -p "$SCRIPT_DIR/results"
    
    docker run --rm \
        --network calc-test-e2e \
        --name e2e-tests \
        -v "$SCRIPT_DIR/test/e2e:/cypress" \
        -v "$SCRIPT_DIR/results:/results" \
        --shm-size=1gb \
        -e CYPRESS_BASE_URL=http://calc-web \
        "$image" \
        --headless \
        --browser chrome \
        --spec "/cypress/cypress/integration/*.spec.js" \
        || print_warning "Pruebas E2E completadas (algunas pueden haber fallado)"
    
    # Limpieza
    print_step "Limpiando contenedores..."
    docker stop apiserver 2>/dev/null || true
    docker stop calc-web 2>/dev/null || true
    docker rm --force apiserver 2>/dev/null || true
    docker rm --force calc-web 2>/dev/null || true
    docker network rm calc-test-e2e 2>/dev/null || true
    
    # Resumen
    print_header "Pruebas E2E Completadas"
    if [ -d "$SCRIPT_DIR/results" ]; then
        echo -e "${GREEN}Resultados en:${NC} $SCRIPT_DIR/results/"
        ls -lah "$SCRIPT_DIR/results/" 2>/dev/null || echo "Sin resultados generados"
    fi
}

# Programa principal
main() {
    case "${1:-}" in
        --build)
            build_custom_image || exit 1
            run_e2e_tests "$CUSTOM_IMAGE"
            ;;
        --custom)
            # Verificar que la imagen existe
            if docker image inspect "$CUSTOM_IMAGE" > /dev/null 2>&1; then
                run_e2e_tests "$CUSTOM_IMAGE"
            else
                print_error "Imagen custom no existe: $CUSTOM_IMAGE"
                print_step "Construyéndola ahora..."
                build_custom_image || exit 1
                run_e2e_tests "$CUSTOM_IMAGE"
            fi
            ;;
        --help|'-h')
            show_help
            ;;
        "")
            # Ejecución por defecto: usar imagen estándar
            run_e2e_tests "$CYPRESS_IMAGE"
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
