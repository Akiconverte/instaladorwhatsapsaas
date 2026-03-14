#!/bin/bash
#
# DV (Dispositivo Virtual) configuration functions

#######################################
# Configures DV in database
# Arguments:
#   None
#######################################
dv_database_config() {
  print_banner
  printf "${WHITE} 💻 Configurando DV no banco de dados PostgreSQL...${GRAY_LIGHT}"
  printf "\n\n"
  
  sleep 2
  
  # Conecta ao banco de dados e insere/atualiza configurações do DV
  sudo -u postgres psql -d user_banco -c "
    INSERT INTO dv_configs (instancia, phone, name, description, welcome_message, away_message, created_at, updated_at)
    VALUES ('${dv_instancia}', '${dv_phone}', '${dv_name}', '${dv_description}', '${dv_welcome_msg}', '${dv_away_msg}', NOW(), NOW())
    ON CONFLICT (instancia) 
    DO UPDATE SET 
      phone = EXCLUDED.phone,
      name = EXCLUDED.name,
      description = EXCLUDED.description,
      welcome_message = EXCLUDED.welcome_message,
      away_message = EXCLUDED.away_message,
      updated_at = NOW();
  " 2>/dev/null || {
    printf "${RED} ❌ Erro ao conectar ao banco de dados. Verifique as configurações PostgreSQL.${GRAY_LIGHT}"
    printf "\n\n"
    return 1
  }
  
  printf "${GREEN} ✅ DV configurado no banco de dados com sucesso!${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
}

#######################################
# Updates DV configuration files
# Arguments:
#   None
#######################################
dv_update_files() {
  print_banner
  printf "${WHITE} 💻 Atualizando arquivos de configuração do DV...${GRAY_LIGHT}"
  printf "\n\n"
  
  sleep 2
  
  # Cria arquivo de configuração do DV na instância
  sudo -u deploy mkdir -p /home/deploy/${dv_instancia}/config
  
  cat << EOF | sudo -u deploy tee /home/deploy/${dv_instancia}/config/dv.json
{
  "instancia": "${dv_instancia}",
  "phone": "${dv_phone}",
  "name": "${dv_name}",
  "description": "${dv_description}",
  "welcome_message": "${dv_welcome_msg}",
  "away_message": "${dv_away_msg}",
  "configured_at": "$(date -Iseconds)",
  "status": "active"
}
EOF
  
  # Atualiza arquivo .env se existir
  if [ -f "/home/deploy/${dv_instancia}/backend/.env" ]; then
    sudo -u deploy sed -i "s/DV_PHONE=.*/DV_PHONE=${dv_phone}/" /home/deploy/${dv_instancia}/backend/.env
    sudo -u deploy sed -i "s/DV_NAME=.*/DV_NAME=${dv_name}/" /home/deploy/${dv_instancia}/backend/.env
    sudo -u deploy sed -i "s/DV_DESCRIPTION=.*/DV_DESCRIPTION=${dv_description}/" /home/deploy/${dv_instancia}/backend/.env
  fi
  
  printf "${GREEN} ✅ Arquivos de configuração atualizados com sucesso!${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
}

#######################################
# Restarts services to apply DV config
# Arguments:
#   None
#######################################
dv_restart_services() {
  print_banner
  printf "${WHITE} 💻 Reiniciando serviços para aplicar configuração do DV...${GRAY_LIGHT}"
  printf "\n\n"
  
  sleep 2
  
  # Reinicia PM2 para a instância
  sudo -u deploy pm2 restart ${dv_instancia}-backend 2>/dev/null || {
    printf "${YELLOW} ⚠️  Serviço backend não encontrado ou já parado.${GRAY_LIGHT}"
    printf "\n\n"
  }
  
  sudo -u deploy pm2 restart ${dv_instancia}-frontend 2>/dev/null || {
    printf "${YELLOW} ⚠️  Serviço frontend não encontrado ou já parado.${GRAY_LIGHT}"
    printf "\n\n"
  }
  
  printf "${GREEN} ✅ Serviços reiniciados com sucesso!${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2
}

#######################################
# Shows DV configuration summary
# Arguments:
#   None
#######################################
dv_show_summary() {
  print_banner
  printf "${GREEN} 📋 RESUMO DA CONFIGURAÇÃO DO DV${GRAY_LIGHT}"
  printf "\n\n"
  
  printf "${WHITE} Instância: ${dv_instancia}${GRAY_LIGHT}\n"
  printf "${WHITE} Telefone: ${dv_phone}${GRAY_LIGHT}\n"
  printf "${WHITE} Nome: ${dv_name}${GRAY_LIGHT}\n"
  printf "${WHITE} Descrição: ${dv_description}${GRAY_LIGHT}\n"
  
  if [ ! -z "$dv_welcome_msg" ]; then
    printf "${WHITE} Msg. Boas-vindas: ${dv_welcome_msg}${GRAY_LIGHT}\n"
  fi
  
  if [ ! -z "$dv_away_msg" ]; then
    printf "${WHITE} Msg. Ausência: ${dv_away_msg}${GRAY_LIGHT}\n"
  fi
  
  printf "\n"
  printf "${GREEN} ✅ Configuração concluída com sucesso!${GRAY_LIGHT}"
  printf "\n\n"
}
