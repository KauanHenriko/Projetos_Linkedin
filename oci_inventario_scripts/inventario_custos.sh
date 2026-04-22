#!/bin/bash

COMPARTMENT_OCID="INSIRA AQUI O OCID DO SEU COMPARTIMENTO"
# Cria um nome de arquivo com a data de hoje automaticamente
CSV_FILE="inventario_servidores_$(date +%Y%m%d).csv"

echo "Coletando inventário de Compute e Storage..."

# Cria o cabeçalho do arquivo CSV
echo "Nome;OCPU;RAM(GB);Boot_Volume(GB);Block_Volume(GB)" > "$CSV_FILE"

# Desenha o cabeçalho na tela
echo "+-------------------------------------------+------+------+--------------+---------------+"
printf "| %-41s | %-4s | %-4s | %-12s | %-13s |\n" "Name" "OCPU" "RAM" "Boot Vol(GB)" "Block Vol(GB)"
echo "+-------------------------------------------+------+------+--------------+---------------+"

# Loop lendo OCID, Nome, AD, OCPU e RAM
while IFS="|" read -r INSTANCE_OCID INSTANCE_NAME INSTANCE_AD OCPU RAM; do
    
    # 1. Obter Boot Volume (Sistema Operacional)
    BOOT_GB=0
    BOOT_VOL_ATTACHMENT=$(oci compute boot-volume-attachment list --availability-domain "$INSTANCE_AD" --instance-id "$INSTANCE_OCID" --compartment-id "$COMPARTMENT_OCID" --all 2>/dev/null)
    BOOT_VOLUME_ID=$(echo "$BOOT_VOL_ATTACHMENT" | jq -r '.data[0]."boot-volume-id" // empty' 2>/dev/null)
    
    if [ -n "$BOOT_VOLUME_ID" ]; then
        BOOT_GB=$(oci bv boot-volume get --boot-volume-id "$BOOT_VOLUME_ID" 2>/dev/null | jq -r '.data."size-in-gbs" // 0')
    fi

    # 2. Obter Block Volumes (Discos Adicionais)
    BLOCK_GB=0
    BLOCK_VOL_ATTACHMENTS=$(oci compute volume-attachment list --availability-domain "$INSTANCE_AD" --instance-id "$INSTANCE_OCID" --compartment-id "$COMPARTMENT_OCID" --all 2>/dev/null)
    BLOCK_VOLUME_IDS=$(echo "$BLOCK_VOL_ATTACHMENTS" | jq -r '.data[]? | ."volume-id" // empty' 2>/dev/null)
    
    if [ -n "$BLOCK_VOLUME_IDS" ]; then
        for VOL_ID in $BLOCK_VOLUME_IDS; do
            VOL_SIZE=$(oci bv volume get --volume-id "$VOL_ID" 2>/dev/null | jq -r '.data."size-in-gbs" // 0')
            BLOCK_GB=$((BLOCK_GB + VOL_SIZE))
        done
    fi

    # Imprime a linha da tabela formatada na TELA
    printf "| %-41s | %-4s | %-4s | %-12s | %-13s |\n" "$INSTANCE_NAME" "$OCPU" "$RAM" "$BOOT_GB" "$BLOCK_GB"
    
    # Salva a mesma informação no arquivo CSV
    echo "$INSTANCE_NAME;$OCPU;$RAM;$BOOT_GB;$BLOCK_GB" >> "$CSV_FILE"

done < <(oci compute instance list --compartment-id "$COMPARTMENT_OCID" --all 2>/dev/null | jq -r '.data[]? | select(."lifecycle-state" != "TERMINATED") | "\(.id)|\(."display-name")|\(."availability-domain")|\(."shape-config".ocpus)|\(."shape-config"."memory-in-gbs")"')

echo "+-------------------------------------------+------+------+--------------+---------------+"
echo "✅ Concluído! O arquivo CSV foi gerado com sucesso: $CSV_FILE"
