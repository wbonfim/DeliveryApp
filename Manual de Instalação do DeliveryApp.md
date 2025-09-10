# Manual de Instalação do DeliveryApp

Este manual fornece instruções detalhadas para instalar o DeliveryApp em uma VM Ubuntu 22.04 recém-formatada.

## Requisitos do Sistema

- Ubuntu 22.04 LTS (recém-instalado, sem atualizações)
- Mínimo de 2GB de RAM
- Mínimo de 20GB de espaço em disco
- Conexão com a internet

## Método 1: Instalação Automatizada (Recomendado)

### Passo 1: Baixar o Script de Instalação

Conecte-se à sua VM Ubuntu 22.04 e execute os seguintes comandos:

```bash
# Atualizar lista de pacotes e instalar curl
sudo apt update
sudo apt install -y curl

# Baixar o script de instalação
curl -O https://raw.githubusercontent.com/manus-project/deliveryapp-installer/main/install_deliveryapp.sh
# ou use wget
# wget https://raw.githubusercontent.com/manus-project/deliveryapp-installer/main/install_deliveryapp.sh

# Tornar o script executável
chmod +x install_deliveryapp.sh
```

### Passo 2: Executar o Script de Instalação

```bash
# Executar o script como root
sudo ./install_deliveryapp.sh
```

O script realizará automaticamente todas as etapas necessárias:
- Atualização do sistema
- Instalação de dependências
- Configuração do banco de dados
- Instalação e configuração do backend
- Instalação e configuração do frontend
- Configuração do servidor web
- Configuração do firewall
- Inicialização dos serviços

### Passo 3: Acessar o Aplicativo

Após a conclusão da instalação, você poderá acessar o DeliveryApp através do navegador:

```
http://[endereço-ip-da-sua-vm]
```

## Método 2: Instalação Manual

Se preferir instalar manualmente ou se o script automatizado falhar, siga estas etapas:

### Passo 1: Atualizar o Sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### Passo 2: Instalar Dependências

```bash
# Instalar dependências do sistema
sudo apt install -y curl wget git python3 python3-pip python3-venv postgresql postgresql-contrib nginx certbot python3-certbot-nginx ufw build-essential libpq-dev

# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar pnpm
sudo npm install -g pnpm
```

### Passo 3: Configurar PostgreSQL

```bash
# Iniciar e habilitar PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Criar usuário e banco de dados
sudo -u postgres psql -c "CREATE USER deliveryapp WITH PASSWORD 'deliveryapp123';"
sudo -u postgres psql -c "CREATE DATABASE deliveryapp OWNER deliveryapp;"
sudo -u postgres psql -c "ALTER USER deliveryapp WITH SUPERUSER;"
```

### Passo 4: Configurar Backend

```bash
# Criar diretório de instalação
sudo mkdir -p /opt/deliveryapp/backend
cd /opt/deliveryapp/backend

# Criar ambiente virtual Python
sudo python3 -m venv venv
source venv/bin/activate

# Instalar dependências do Flask
pip install flask flask-sqlalchemy flask-migrate flask-cors flask-jwt-extended psycopg2-binary gunicorn

# Criar estrutura básica do projeto
sudo mkdir -p src/models src/routes migrations
```

Crie o arquivo principal `src/main.py` com o conteúdo apropriado (consulte o script de instalação automatizada para detalhes).

### Passo 5: Configurar Frontend

```bash
# Criar diretório do frontend
sudo mkdir -p /opt/deliveryapp/frontend
cd /opt/deliveryapp/frontend

# Inicializar projeto React
pnpm create vite . --template react
pnpm install
```

Configure os arquivos do frontend conforme necessário (consulte o script de instalação automatizada para detalhes).

### Passo 6: Construir o Frontend

```bash
cd /opt/deliveryapp/frontend
pnpm run build
```

### Passo 7: Configurar Nginx

Crie o arquivo de configuração do Nginx:

```bash
sudo nano /etc/nginx/sites-available/deliveryapp
```

Adicione o seguinte conteúdo:

```nginx
server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        root /opt/deliveryapp/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Ative a configuração:

```bash
sudo ln -sf /etc/nginx/sites-available/deliveryapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

### Passo 8: Configurar Serviço Systemd para o Backend

Crie o arquivo de serviço:

```bash
sudo nano /etc/systemd/system/deliveryapp.service
```

Adicione o seguinte conteúdo:

```ini
[Unit]
Description=DeliveryApp Backend
After=network.target postgresql.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/deliveryapp/backend
Environment="PATH=/opt/deliveryapp/backend/venv/bin"
Environment="FLASK_APP=run.py"
Environment="FLASK_ENV=production"
Environment="DATABASE_URL=postgresql://deliveryapp:deliveryapp123@localhost/deliveryapp"
ExecStart=/opt/deliveryapp/backend/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 run:app
Restart=always

[Install]
WantedBy=multi-user.target
```

Inicie o serviço:

```bash
sudo systemctl daemon-reload
sudo systemctl start deliveryapp
sudo systemctl enable deliveryapp
```

### Passo 9: Configurar Firewall

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw --force enable
```

### Passo 10: Ajustar Permissões

```bash
sudo chown -R www-data:www-data /opt/deliveryapp
sudo chmod -R 755 /opt/deliveryapp
```

## Solução de Problemas

### Verificar Status dos Serviços

```bash
# Verificar status do backend
sudo systemctl status deliveryapp

# Verificar logs do backend
sudo journalctl -u deliveryapp

# Verificar status do Nginx
sudo systemctl status nginx

# Verificar logs do Nginx
sudo tail -f /var/log/nginx/error.log
```

### Problemas Comuns

1. **Erro de conexão com o banco de dados**:
   - Verifique se o PostgreSQL está em execução: `sudo systemctl status postgresql`
   - Verifique as credenciais no arquivo de configuração

2. **Erro 502 Bad Gateway**:
   - Verifique se o backend está em execução: `sudo systemctl status deliveryapp`
   - Verifique os logs do backend: `sudo journalctl -u deliveryapp`

3. **Página em branco no frontend**:
   - Verifique os logs do Nginx: `sudo tail -f /var/log/nginx/error.log`
   - Verifique se os arquivos estáticos estão sendo servidos corretamente

4. **Problemas de permissão**:
   - Verifique as permissões dos diretórios: `ls -la /opt/deliveryapp`
   - Ajuste as permissões se necessário: `sudo chown -R www-data:www-data /opt/deliveryapp`

## Uso do Aplicativo como PWA

Para instalar o DeliveryApp como um aplicativo progressivo (PWA) em dispositivos móveis:

1. Acesse o site em um navegador moderno (Chrome, Safari, Edge)
2. No menu do navegador, procure por "Adicionar à tela inicial" ou "Instalar aplicativo"
3. Siga as instruções na tela para completar a instalação

Após a instalação, o DeliveryApp aparecerá como um aplicativo na tela inicial do seu dispositivo e poderá ser usado offline.

## Informações Adicionais

- **Backend API**: http://[endereço-ip-da-sua-vm]/api
- **Logs do backend**: `sudo journalctl -u deliveryapp`
- **Logs do Nginx**: `/var/log/nginx/access.log` e `/var/log/nginx/error.log`
- **Log de instalação**: `/var/log/deliveryapp_install.log`

## Suporte

Para obter suporte ou relatar problemas, entre em contato através do e-mail: suporte@deliveryapp.com

