#!/bin/bash

# ==========================================
# VARIÁVEL - COMPARTMENT OCID
# ==========================================
COMPARTMENT_OCID=#"# INSIRA AQUI O OCID DO SEU COMPARTIMENTO"
RATE_PER_GB="# VALOR DO CUSTO POR GB DO BACKUP"

GRAND_TOTAL_BKP=0
GRAND_TOTAL_CUSTO=0.00

echo "-------------------------------------------------------------------------------------------------"
printf "%-35s | %-21s | %-30s |\n" "Nome da instacia" "TOTAL DE GB DE BACKUP" "CUSTO TOTAL DOS GB DE BACKUP"
echo "-------------------------------------------------------------------------------------------------"

# Usando substituição de processo < <() para não criar sub-shell e manter o Total no final
while IFS="|" read -r INSTANCE_OCID INSTANCE_NAME INSTANCE_AD; do
    
    INSTANCE_TOTAL_GB=0

    # 1. Boot Volumes (Sistema Operacional)
    BOOT_VOL_ATTACHMENT=$(oci compute boot-volume-attachment list --availability-domain "$INSTANCE_AD" --instance-id "$INSTANCE_OCID" --compartment-id "$COMPARTMENT_OCID" --all 2>/dev/null)
    BOOT_VOLUME_ID=$(echo "$BOOT_VOL_ATTACHMENT" | jq -r '.data[0]."boot-volume-id" // empty' 2>/dev/null)

    if [ -n "$BOOT_VOLUME_ID" ]; then
        BKP_JSON=$(oci bv boot-volume-backup list --boot-volume-id "$BOOT_VOLUME_ID" --compartment-id "$COMPARTMENT_OCID" --all 2>/dev/null)
        BOOT_BKP_SIZE=$(echo "$BKP_JSON" | jq -r '[.data[]? | (."unique-size-in-gbs" // 0) | tonumber] | add // 0' 2>/dev/null)
        
        if [ -z "$BOOT_BKP_SIZE" ] || [ "$BOOT_BKP_SIZE" == "null" ]; then BOOT_BKP_SIZE=0; fi
        INSTANCE_TOTAL_GB=$(awk "BEGIN {print $INSTANCE_TOTAL_GB + $BOOT_BKP_SIZE}")
    fi

    # 2. Block Volumes (Discos Adicionais)
    BLOCK_VOL_ATTACHMENTS=$(oci compute volume-attachment list --availability-domain "$INSTANCE_AD" --instance-id "$INSTANCE_OCID" --compartment-id "$COMPARTMENT_OCID" --all 2>/dev/null)
    BLOCK_VOLUME_IDS=$(echo "$BLOCK_VOL_ATTACHMENTS" | jq -r '.data[]? | ."volume-id" // empty' 2>/dev/null)

    if [ -n "$BLOCK_VOLUME_IDS" ]; then
        for VOL_ID in $BLOCK_VOLUME_IDS; do
            # AQUI ESTAVA O ERRO! COMANDO CORRIGIDO PARA: oci bv backup list
            BKP_JSON=$(oci bv backup list --volume-id "$VOL_ID" --compartment-id "$COMPARTMENT_OCID" --all 2>/dev/null)
            BLOCK_BKP_SIZE=$(echo "$BKP_JSON" | jq -r '[.data[]? | (."unique-size-in-gbs" // 0) | tonumber] | add // 0' 2>/dev/null)
            
            if [ -z "$BLOCK_BKP_SIZE" ] || [ "$BLOCK_BKP_SIZE" == "null" ]; then BLOCK_BKP_SIZE=0; fi
            INSTANCE_TOTAL_GB=$(awk "BEGIN {print $INSTANCE_TOTAL_GB + $BLOCK_BKP_SIZE}")
        done
    fi

    # 3. Consolidação e Cálculo Financeiro
    if [ -z "$INSTANCE_TOTAL_GB" ] || [ "$INSTANCE_TOTAL_GB" == "0" ]; then
        CUSTO_TOTAL="0.00"
        INSTANCE_TOTAL_GB="0"
    else
        CUSTO_TOTAL=$(awk "BEGIN {printf \"%.2f\", $INSTANCE_TOTAL_GB * $RATE_PER_GB}")
    fi

    # Atualiza o Totalizador Geral
    GRAND_TOTAL_BKP=$(awk "BEGIN {print $GRAND_TOTAL_BKP + $INSTANCE_TOTAL_GB}")
    GRAND_TOTAL_CUSTO=$(awk "BEGIN {printf \"%.2f\", $GRAND_TOTAL_CUSTO + $CUSTO_TOTAL}")

    # Imprime a linha formatada com R$
    printf "%-35s | %-21s | R$ %-27s |\n" "$INSTANCE_NAME" "${INSTANCE_TOTAL_GB} GB" "$CUSTO_TOTAL"

done < <(oci compute instance list --compartment-id "$COMPARTMENT_OCID" --all 2>/dev/null | jq -r '.data[]? | select(."lifecycle-state" != "TERMINATED") | "\(.id)|\(."display-name")|\(."availability-domain")"')

echo "================================================================================================="
printf "%-35s | %-21s | R$ %-27s |\n" "TOTAL GERAL DA INFRAESTRUTURA" "${GRAND_TOTAL_BKP} GB" "$GRAND_TOTAL_CUSTO"
echo "================================================================================================="
