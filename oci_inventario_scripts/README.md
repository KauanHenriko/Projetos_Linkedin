# ☁️OCI FinOps & Inventory Automation Suite

Esta suíte de ferramentas em Shell Script (Bash) foi desenvolvida para automatizar a auditoria de recursos e o controle de custos em ambientes Oracle Cloud Infrastructure (OCI). O foco do projeto é transformar processos de levantamento manual em extrações precisas e dinâmicas via API.

## 🎯 Contexto do Projeto

Em infraestruturas de nuvem complexas, a separação arquitetural entre recursos de processamento (Compute) e armazenamento (Storage) exige o cruzamento de dados de diferentes APIs para se obter uma visão real da infraestrutura. Este projeto foca na cultura SRE para eliminar o trabalho manual repetitivo, garantindo que o inventário e o faturamento de cada instância sejam auditados com rapidez e precisão.

## 🛠️ Funcionalidades

A suíte é composta por dois módulos principais:

1. **Inventário Geral (`inventario_custos.sh`)**: Mapeia em cascata o *shape* das instâncias (OCPU e RAM) e realiza a soma dinâmica de todos os volumes de disco (Boot e Block Volumes) atachados. Exporta os dados consolidados e estruturados em um arquivo `.csv`, pronto para análise gerencial.
2. **Auditoria de Backup (`calcula_backup.sh`)**: Atua como uma calculadora financeira em tempo real no terminal. Identifica cada backup vinculado aos volumes das instâncias ativas e calcula o custo projetado com base na volumetria total de dados em Gigabytes.

## 🚀 Tecnologias Utilizadas

* **Bash / Shell Script**: Orquestração do fluxo de execução, loops de repetição e substituição de processos (`< <()`).
* **OCI CLI**: Interface nativa para comunicação com as APIs da Oracle Cloud.
* **jq**: Processamento, extração e filtragem de objetos JSON aninhados retornados pela API.
* **awk**: Realização de cálculos matemáticos de ponto flutuante para garantir precisão financeira na linha de comando.

## ⚙️ Guia de Uso

### Pré-requisitos
* Ter a **OCI CLI** instalada e autenticada com as credenciais da sua *tenancy*.
* Ter o utilitário **jq** instalado no seu sistema.

## 🛠️Instalação e Configuração

1. Clone este repositório para o seu ambiente local:
```bash

git clone [https://github.com/KauanHenriko/Projetos_Linkedin.git](https://github.com/KauanHenriko/Projetos_Linkedin.git)

```

2.  Acesse a pasta do projeto:
   ```bash

cd Projetos_Linkedin/oci_inventario_scripts

```

3.  **Configuração do Inventário (`inventario_custos.sh`)**: Abra o script em um editor de texto e insira o OCID do compartimento que deseja auditar na variável:
    
 ```bash
 
COMPARTMENT_OCID="[SEU_OCID_AQUI]"

```

4.  **Configuração da Calculadora FinOps (`calcula_backup.sh`)**: Abra o script e preencha tanto o OCID do compartimento quanto o valor atualizado cobrado por GB de backup na sua região (caso o valor não seja preenchido, o cálculo financeiro retornará zero):
    
```bash

COMPARTMENT_OCID="ocid1.compartment.oc1..[SEU_OCID_AQUI]"
RATE_PER_GB=0.00 # Insira o valor do custo por GB de backup

```
5. Defina as permissões de execução para os scripts:
    

```bash

chmod +x inventario_custos.sh calcula_backup.sh

```

## 💻Execução

* Para gerar o inventário em formato de planilha `.csv`:

```bash

./inventario_custos.sh

```

* Para visualizar a auditoria e os custos de backup diretamente no terminal:


```bash

./calcula_backup.sh

```

----------

_Desenvolvido com foco em automação de infraestrutura, FinOps e cultura DevOps.❤️_
