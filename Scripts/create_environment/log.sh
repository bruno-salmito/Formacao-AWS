#!/bin/bash

# log.sh - Sistema de logging para operações IAM

# Configurações de log
LOG_DIR="/tmp"
#LOG_FILE="$LOG_DIR/iam_operations_$(date +%Y%m%d).log"
LOG_FILE="$LOG_DIR/create_environment.log"

# Criar diretório de logs se não existir
create_log_dir() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
    fi
}

# Função para escrever log com timestamp
write_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    create_log_dir
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Funções específicas de log
log_info() {
    local message="$1"
    write_log "INFO" "$message"
    echo -e "${BLUE}[INFO]${NC} $message"
}

log_success() {
    local message="$1"
    write_log "SUCCESS" "$message"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
}

log_warning() {
    local message="$1"
    write_log "WARNING" "$message"
    echo -e "${YELLOW}[WARNING]${NC} $message"
}

log_error() {
    local message="$1"
    write_log "ERROR" "$message"
    echo -e "${RED}[ERROR]${NC} $message"
}

# Função para log de início de operação
log_operation_start() {
    local operation="$1"
    log_info "Iniciando operação: $operation"
}

# Função para log de fim de operação
log_operation_end() {
    local operation="$1"
    local status="$2"
    
    if [[ "$status" == "0" ]]; then
        log_success "Operação concluída com sucesso: $operation"
    else
        log_error "Operação falhou: $operation (código de saída: $status)"
    fi
}

# Função para exibir logs recentes
show_recent_logs() {
    local lines="${1:-20}"
    
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${BLUE}Últimas $lines entradas do log:${NC}"
        tail -n "$lines" "$LOG_FILE"
    else
        log_warning "Arquivo de log não encontrado: $LOG_FILE"
    fi
}


# Função para logging
log_message() {
    echo "[${TIMESTAMP}] [${USER}] $1" >> "${LOG_FILE}"
}