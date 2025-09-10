#!/bin/bash

# Script de instalação do DeliveryApp
# Para Ubuntu 22.04 LTS recém-formatado
# Autor: Manus AI

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir mensagens de progresso
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para verificar se o último comando foi executado com sucesso
check_status() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "$2"
        exit 1
    fi
}

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script precisa ser executado como root (sudo)."
    echo "Por favor, execute: sudo bash install_deliveryapp.sh"
    exit 1
fi

# Verificar se é Ubuntu 22.04
if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu 22.04" /etc/os-release; then
    print_warning "Este script foi projetado para Ubuntu 22.04 LTS."
    echo "Deseja continuar mesmo assim? (s/n)"
    read -r response
    if [[ ! "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        print_status "Instalação cancelada."
        exit 0
    fi
fi

# Diretório de instalação
INSTALL_DIR="/opt/deliveryapp"
BACKEND_DIR="$INSTALL_DIR/backend"
FRONTEND_DIR="$INSTALL_DIR/frontend"
LOG_FILE="/var/log/deliveryapp_install.log"

# Criar diretório de log
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Função para registrar logs
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Início da instalação
clear
echo "================================================================="
echo "                 INSTALAÇÃO DO DELIVERYAPP                        "
echo "================================================================="
echo ""
echo "Este script irá instalar o DeliveryApp completo em seu servidor."
echo "O processo inclui:"
echo "  - Atualização do sistema"
echo "  - Instalação de dependências (Python, Node.js, PostgreSQL, etc.)"
echo "  - Configuração do backend (Flask)"
echo "  - Configuração do frontend (React)"
echo "  - Configuração do servidor web (Nginx)"
echo "  - Configuração do serviço systemd"
echo ""
echo "O processo pode levar alguns minutos."
echo "================================================================="
echo ""
echo "Pressione ENTER para continuar ou CTRL+C para cancelar..."
read -r

log "Iniciando instalação do DeliveryApp"

# Atualizar sistema
print_status "Atualizando lista de pacotes..."
apt-get update >> "$LOG_FILE" 2>&1
check_status "Lista de pacotes atualizada." "Falha ao atualizar lista de pacotes. Verifique o log: $LOG_FILE"

print_status "Instalando atualizações essenciais de segurança..."
apt-get -y upgrade >> "$LOG_FILE" 2>&1
check_status "Sistema atualizado." "Falha ao atualizar o sistema. Verifique o log: $LOG_FILE"

# Instalar dependências
print_status "Instalando dependências do sistema..."
apt-get install -y curl wget git python3 python3-pip python3-venv postgresql postgresql-contrib nginx certbot python3-certbot-nginx ufw build-essential libpq-dev >> "$LOG_FILE" 2>&1
check_status "Dependências do sistema instaladas." "Falha ao instalar dependências. Verifique o log: $LOG_FILE"

# Instalar Node.js
print_status "Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - >> "$LOG_FILE" 2>&1
apt-get install -y nodejs >> "$LOG_FILE" 2>&1
check_status "Node.js instalado." "Falha ao instalar Node.js. Verifique o log: $LOG_FILE"

# Instalar pnpm
print_status "Instalando pnpm..."
npm install -g pnpm >> "$LOG_FILE" 2>&1
check_status "pnpm instalado." "Falha ao instalar pnpm. Verifique o log: $LOG_FILE"

# Criar diretório de instalação
print_status "Criando diretórios de instalação..."
mkdir -p "$BACKEND_DIR" "$FRONTEND_DIR"
check_status "Diretórios criados." "Falha ao criar diretórios."

# Configurar PostgreSQL
print_status "Configurando banco de dados PostgreSQL..."
# Verificar se o serviço está rodando
systemctl start postgresql
systemctl enable postgresql
check_status "PostgreSQL iniciado e habilitado." "Falha ao iniciar PostgreSQL."

# Criar usuário e banco de dados
su - postgres -c "psql -c \"CREATE USER deliveryapp WITH PASSWORD 'deliveryapp123'\"" >> "$LOG_FILE" 2>&1
su - postgres -c "psql -c \"CREATE DATABASE deliveryapp OWNER deliveryapp\"" >> "$LOG_FILE" 2>&1
su - postgres -c "psql -c \"ALTER USER deliveryapp WITH SUPERUSER\"" >> "$LOG_FILE" 2>&1
check_status "Banco de dados configurado." "Falha ao configurar banco de dados."

# Clonar repositório do backend
print_status "Baixando código do backend..."
git clone https://github.com/manus-project/deliveryapp-backend.git "$BACKEND_DIR" >> "$LOG_FILE" 2>&1 || {
    # Se o repositório não existir, criar estrutura básica
    print_warning "Repositório não encontrado. Criando estrutura básica do backend..."
    
    # Criar ambiente virtual Python
    python3 -m venv "$BACKEND_DIR/venv"
    source "$BACKEND_DIR/venv/bin/activate"
    
    # Instalar Flask e dependências
    pip install flask flask-sqlalchemy flask-migrate flask-cors flask-jwt-extended psycopg2-binary gunicorn >> "$LOG_FILE" 2>&1
    
    # Criar estrutura básica do projeto
    mkdir -p "$BACKEND_DIR/src/models" "$BACKEND_DIR/src/routes" "$BACKEND_DIR/migrations"
    
    # Criar arquivo principal
    cat > "$BACKEND_DIR/src/main.py" << 'EOF'
from flask import Flask, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
import os

# Inicializar aplicação
app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Configuração
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'postgresql://deliveryapp:deliveryapp123@localhost/deliveryapp')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'super-secret-key-change-in-production')

# Inicializar extensões
db = SQLAlchemy(app)
migrate = Migrate(app, db)
jwt = JWTManager(app)

# Modelos
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(120), nullable=False)
    full_name = db.Column(db.String(120))
    is_admin = db.Column(db.Boolean, default=False)
    
    def __repr__(self):
        return f'<User {self.username}>'

class Restaurant(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    description = db.Column(db.Text)
    address = db.Column(db.String(200))
    phone = db.Column(db.String(20))
    image_url = db.Column(db.String(200))
    rating = db.Column(db.Float, default=0.0)
    delivery_time = db.Column(db.Integer, default=30)  # em minutos
    delivery_fee = db.Column(db.Float, default=0.0)
    is_online = db.Column(db.Boolean, default=True)
    category_id = db.Column(db.Integer, db.ForeignKey('category.id'))
    
    def __repr__(self):
        return f'<Restaurant {self.name}>'

class Category(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    restaurants = db.relationship('Restaurant', backref='category', lazy=True)
    
    def __repr__(self):
        return f'<Category {self.name}>'

# Rotas
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "message": "API is running"})

@app.route('/api/restaurants', methods=['GET'])
def get_restaurants():
    restaurants = Restaurant.query.all()
    result = []
    for restaurant in restaurants:
        result.append({
            'id': restaurant.id,
            'name': restaurant.name,
            'description': restaurant.description,
            'address': restaurant.address,
            'phone': restaurant.phone,
            'image_url': restaurant.image_url,
            'rating': restaurant.rating,
            'delivery_time': restaurant.delivery_time,
            'delivery_fee': restaurant.delivery_fee,
            'is_online': restaurant.is_online,
            'category': {
                'id': restaurant.category.id,
                'name': restaurant.category.name
            } if restaurant.category else None
        })
    return jsonify(result)

@app.route('/api/categories', methods=['GET'])
def get_categories():
    categories = Category.query.all()
    result = []
    for category in categories:
        result.append({
            'id': category.id,
            'name': category.name
        })
    return jsonify(result)

# Inicializar banco de dados com dados de exemplo
@app.before_first_request
def create_tables():
    db.create_all()
    
    # Verificar se já existem dados
    if Category.query.count() == 0:
        # Criar categorias
        categories = [
            Category(name='Lanches'),
            Category(name='Pizza'),
            Category(name='Japonesa'),
            Category(name='Brasileira'),
            Category(name='Italiana'),
            Category(name='Saudável'),
            Category(name='Doces'),
            Category(name='Bebidas')
        ]
        db.session.add_all(categories)
        db.session.commit()
        
        # Criar restaurantes
        restaurants = [
            Restaurant(
                name='Burger King',
                description='Hamburgers e lanches rápidos',
                address='Av. Paulista, 1000',
                phone='(11) 99999-8888',
                image_url='https://via.placeholder.com/400x300?text=Burger+King',
                rating=4.5,
                delivery_time=30,
                delivery_fee=5.90,
                is_online=True,
                category_id=1
            ),
            Restaurant(
                name='Pizza Hut',
                description='As melhores pizzas da cidade',
                address='Rua Augusta, 500',
                phone='(11) 99999-7777',
                image_url='https://via.placeholder.com/400x300?text=Pizza+Hut',
                rating=4.3,
                delivery_time=45,
                delivery_fee=6.90,
                is_online=True,
                category_id=2
            ),
            Restaurant(
                name='Sushi Japão',
                description='Comida japonesa tradicional',
                address='Rua Liberdade, 200',
                phone='(11) 99999-6666',
                image_url='https://via.placeholder.com/400x300?text=Sushi+Japao',
                rating=4.7,
                delivery_time=50,
                delivery_fee=8.90,
                is_online=True,
                category_id=3
            ),
            Restaurant(
                name='Feijoada Express',
                description='A melhor feijoada da cidade',
                address='Av. Ipiranga, 800',
                phone='(11) 99999-5555',
                image_url='https://via.placeholder.com/400x300?text=Feijoada+Express',
                rating=4.6,
                delivery_time=40,
                delivery_fee=7.50,
                is_online=False,
                category_id=4
            ),
            Restaurant(
                name='Cantina da Nonna',
                description='Massas artesanais italianas',
                address='Rua Avanhandava, 150',
                phone='(11) 99999-4444',
                image_url='https://via.placeholder.com/400x300?text=Cantina+da+Nonna',
                rating=4.8,
                delivery_time=55,
                delivery_fee=9.90,
                is_online=True,
                category_id=5
            ),
            Restaurant(
                name='Salada & Cia',
                description='Comida saudável e nutritiva',
                address='Av. Brigadeiro Faria Lima, 1500',
                phone='(11) 99999-3333',
                image_url='https://via.placeholder.com/400x300?text=Salada+%26+Cia',
                rating=4.2,
                delivery_time=25,
                delivery_fee=4.90,
                is_online=True,
                category_id=6
            ),
            Restaurant(
                name='Doce Sabor',
                description='Sobremesas e doces gourmet',
                address='Rua Oscar Freire, 300',
                phone='(11) 99999-2222',
                image_url='https://via.placeholder.com/400x300?text=Doce+Sabor',
                rating=4.9,
                delivery_time=20,
                delivery_fee=6.50,
                is_online=True,
                category_id=7
            ),
            Restaurant(
                name='Bar do Zé',
                description='Cervejas artesanais e petiscos',
                address='Rua Augusta, 1000',
                phone='(11) 99999-1111',
                image_url='https://via.placeholder.com/400x300?text=Bar+do+Ze',
                rating=4.4,
                delivery_time=35,
                delivery_fee=7.90,
                is_online=False,
                category_id=8
            )
        ]
        db.session.add_all(restaurants)
        db.session.commit()

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
EOF

    # Criar arquivo de inicialização
    cat > "$BACKEND_DIR/run.py" << 'EOF'
from src.main import app

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

    # Criar arquivo de requisitos
    cat > "$BACKEND_DIR/requirements.txt" << 'EOF'
flask==2.2.3
flask-sqlalchemy==3.0.3
flask-migrate==4.0.4
flask-cors==3.0.10
flask-jwt-extended==4.4.4
psycopg2-binary==2.9.5
gunicorn==20.1.0
EOF

    check_status "Estrutura básica do backend criada." "Falha ao criar estrutura do backend."
}

# Configurar backend
print_status "Configurando backend..."
cd "$BACKEND_DIR" || exit 1

# Criar ambiente virtual se não existir
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Ativar ambiente virtual
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || pip install flask flask-sqlalchemy flask-migrate flask-cors flask-jwt-extended psycopg2-binary gunicorn >> "$LOG_FILE" 2>&1
check_status "Dependências do backend instaladas." "Falha ao instalar dependências do backend."

# Configurar variáveis de ambiente
cat > "$BACKEND_DIR/.env" << EOF
FLASK_APP=run.py
FLASK_ENV=production
DATABASE_URL=postgresql://deliveryapp:deliveryapp123@localhost/deliveryapp
JWT_SECRET_KEY=$(openssl rand -hex 32)
EOF

# Inicializar banco de dados
export FLASK_APP=run.py
flask db init >> "$LOG_FILE" 2>&1 || echo "Migrations já inicializadas"
flask db migrate -m "initial migration" >> "$LOG_FILE" 2>&1
flask db upgrade >> "$LOG_FILE" 2>&1
check_status "Banco de dados inicializado." "Aviso: Possível problema ao inicializar banco de dados."

# Desativar ambiente virtual
deactivate

# Clonar repositório do frontend
print_status "Baixando código do frontend..."
git clone https://github.com/manus-project/deliveryapp-frontend.git "$FRONTEND_DIR" >> "$LOG_FILE" 2>&1 || {
    # Se o repositório não existir, criar estrutura básica
    print_warning "Repositório não encontrado. Criando estrutura básica do frontend..."
    
    # Criar projeto React
    mkdir -p "$FRONTEND_DIR/public" "$FRONTEND_DIR/src/components" "$FRONTEND_DIR/src/contexts"
    
    # Criar package.json
    cat > "$FRONTEND_DIR/package.json" << 'EOF'
{
  "name": "delivery-frontend",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "lint": "eslint . --ext js,jsx --report-unused-disable-directives --max-warnings 0",
    "preview": "vite preview"
  },
  "dependencies": {
    "@radix-ui/react-avatar": "^1.0.4",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-tabs": "^1.0.4",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "lucide-react": "^0.358.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "tailwind-merge": "^2.2.1",
    "tailwindcss-animate": "^1.0.7"
  },
  "devDependencies": {
    "@types/node": "^20.11.30",
    "@types/react": "^18.2.66",
    "@types/react-dom": "^18.2.22",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.18",
    "eslint": "^8.57.0",
    "eslint-plugin-react": "^7.34.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "vite": "^5.1.6"
  }
}
EOF

    # Criar index.html
    cat > "$FRONTEND_DIR/index.html" << 'EOF'
<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    
    <!-- PWA Meta Tags -->
    <meta name="theme-color" content="#dc2626" />
    <meta name="description" content="DeliveryApp - Seu aplicativo de delivery favorito com os melhores restaurantes da cidade" />
    <meta name="keywords" content="delivery, comida, restaurante, pedido, food, app" />
    <meta name="author" content="DeliveryApp Team" />
    
    <!-- PWA Apple Meta Tags -->
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="default" />
    <meta name="apple-mobile-web-app-title" content="DeliveryApp" />
    <link rel="apple-touch-icon" href="/icons/icon-192x192.png" />
    
    <!-- PWA Microsoft Meta Tags -->
    <meta name="msapplication-TileColor" content="#dc2626" />
    <meta name="msapplication-TileImage" content="/icons/icon-144x144.png" />
    
    <!-- PWA Manifest -->
    <link rel="manifest" href="/manifest.json" />
    
    <title>DeliveryApp - Seu delivery favorito</title>
  </head>
  <body>
    <div id="root"></div>
    
    <!-- PWA Install Banner -->
    <div id="pwa-install-banner" style="display: none; position: fixed; bottom: 20px; left: 20px; right: 20px; background: #dc2626; color: white; padding: 16px; border-radius: 8px; z-index: 1000; box-shadow: 0 4px 12px rgba(0,0,0,0.3);">
      <div style="display: flex; align-items: center; justify-content: space-between;">
        <div>
          <strong>Instalar DeliveryApp</strong>
          <p style="margin: 4px 0 0 0; font-size: 14px; opacity: 0.9;">Instale o app para uma experiência melhor!</p>
        </div>
        <div>
          <button id="pwa-install-btn" style="background: white; color: #dc2626; border: none; padding: 8px 16px; border-radius: 4px; font-weight: bold; margin-right: 8px; cursor: pointer;">Instalar</button>
          <button id="pwa-dismiss-btn" style="background: transparent; color: white; border: 1px solid white; padding: 8px 12px; border-radius: 4px; cursor: pointer;">✕</button>
        </div>
      </div>
    </div>
    
    <script type="module" src="/src/main.jsx"></script>
    
    <!-- PWA Service Worker Registration -->
    <script>
      // Registrar Service Worker
      if ('serviceWorker' in navigator) {
        window.addEventListener('load', () => {
          navigator.serviceWorker.register('/sw.js')
            .then((registration) => {
              console.log('SW registered: ', registration);
            })
            .catch((registrationError) => {
              console.log('SW registration failed: ', registrationError);
            });
        });
      }
      
      // PWA Install Prompt
      let deferredPrompt;
      const installBanner = document.getElementById('pwa-install-banner');
      const installBtn = document.getElementById('pwa-install-btn');
      const dismissBtn = document.getElementById('pwa-dismiss-btn');
      
      window.addEventListener('beforeinstallprompt', (e) => {
        e.preventDefault();
        deferredPrompt = e;
        installBanner.style.display = 'block';
      });
      
      installBtn.addEventListener('click', async () => {
        if (deferredPrompt) {
          deferredPrompt.prompt();
          const { outcome } = await deferredPrompt.userChoice;
          console.log(`User response to the install prompt: ${outcome}`);
          deferredPrompt = null;
          installBanner.style.display = 'none';
        }
      });
      
      dismissBtn.addEventListener('click', () => {
        installBanner.style.display = 'none';
        localStorage.setItem('pwa-install-dismissed', Date.now());
      });
      
      // Detectar quando o app foi instalado
      window.addEventListener('appinstalled', (evt) => {
        console.log('DeliveryApp foi instalado!');
        installBanner.style.display = 'none';
      });
      
      // Detectar mudanças na conectividade
      function updateOnlineStatus() {
        if (!navigator.onLine) {
          const offlineIndicator = document.createElement('div');
          offlineIndicator.id = 'offline-indicator';
          offlineIndicator.innerHTML = '📶 Você está offline';
          offlineIndicator.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: #f59e0b;
            color: white;
            text-align: center;
            padding: 8px;
            z-index: 9999;
            font-size: 14px;
          `;
          document.body.insertBefore(offlineIndicator, document.body.firstChild);
        } else {
          const indicator = document.getElementById('offline-indicator');
          if (indicator) {
            indicator.remove();
          }
        }
      }
      
      window.addEventListener('online', updateOnlineStatus);
      window.addEventListener('offline', updateOnlineStatus);
      updateOnlineStatus();
    </script>
  </body>
</html>
EOF

    # Criar manifest.json
    mkdir -p "$FRONTEND_DIR/public"
    cat > "$FRONTEND_DIR/public/manifest.json" << 'EOF'
{
  "name": "DeliveryApp - Seu delivery favorito",
  "short_name": "DeliveryApp",
  "description": "Aplicativo de delivery de comida com os melhores restaurantes da cidade",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#dc2626",
  "orientation": "portrait-primary",
  "scope": "/",
  "lang": "pt-BR",
  "categories": ["food", "shopping", "lifestyle"],
  "icons": [
    {
      "src": "/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-128x128.png",
      "sizes": "128x128",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-152x152.png",
      "sizes": "152x152",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable any"
    }
  ]
}
EOF

    # Criar service worker
    cat > "$FRONTEND_DIR/public/sw.js" << 'EOF'
// Service Worker para DeliveryApp PWA
const CACHE_NAME = 'deliveryapp-v1.0.0';
const STATIC_CACHE_NAME = 'deliveryapp-static-v1.0.0';
const DYNAMIC_CACHE_NAME = 'deliveryapp-dynamic-v1.0.0';

// Arquivos para cache estático (sempre em cache)
const STATIC_FILES = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// Instalar Service Worker
self.addEventListener('install', (event) => {
  console.log('Service Worker: Installing...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE_NAME)
      .then((cache) => {
        console.log('Service Worker: Caching static files');
        return cache.addAll(STATIC_FILES);
      })
      .then(() => {
        console.log('Service Worker: Static files cached');
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('Service Worker: Error caching static files:', error);
      })
  );
});

// Ativar Service Worker
self.addEventListener('activate', (event) => {
  console.log('Service Worker: Activating...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            // Remover caches antigos
            if (cacheName !== STATIC_CACHE_NAME && 
                cacheName !== DYNAMIC_CACHE_NAME &&
                cacheName.startsWith('deliveryapp-')) {
              console.log('Service Worker: Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log('Service Worker: Activated');
        return self.clients.claim();
      })
  );
});

// Interceptar requisições
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Estratégia Cache First para arquivos estáticos
  if (STATIC_FILES.some(file => url.pathname === file) || 
      request.destination === 'script' || 
      request.destination === 'style' ||
      request.destination === 'image') {
    
    event.respondWith(
      caches.match(request)
        .then((cachedResponse) => {
          if (cachedResponse) {
            return cachedResponse;
          }
          
          return fetch(request)
            .then((response) => {
              if (response.status === 200) {
                const responseClone = response.clone();
                caches.open(STATIC_CACHE_NAME)
                  .then((cache) => {
                    cache.put(request, responseClone);
                  });
              }
              return response;
            });
        })
        .catch(() => {
          // Fallback para página offline
          if (request.destination === 'document') {
            return caches.match('/');
          }
        })
    );
    return;
  }
  
  // Estratégia Network First para APIs
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          if (response.status === 200) {
            const responseClone = response.clone();
            caches.open(DYNAMIC_CACHE_NAME)
              .then((cache) => {
                cache.put(request, responseClone);
              });
          }
          return response;
        })
        .catch(() => {
          // Fallback para cache se offline
          return caches.match(request)
            .then((cachedResponse) => {
              if (cachedResponse) {
                return cachedResponse;
              }
              
              // Resposta padrão para APIs offline
              return new Response(
                JSON.stringify({
                  error: 'Você está offline. Alguns dados podem estar desatualizados.',
                  offline: true
                }),
                {
                  status: 200,
                  headers: {
                    'Content-Type': 'application/json'
                  }
                }
              );
            });
        })
    );
    return;
  }
  
  // Estratégia padrão Network First
  event.respondWith(
    fetch(request)
      .then((response) => {
        if (response.status === 200) {
          const responseClone = response.clone();
          caches.open(DYNAMIC_CACHE_NAME)
            .then((cache) => {
              cache.put(request, responseClone);
            });
        }
        return response;
      })
      .catch(() => {
        return caches.match(request)
          .then((cachedResponse) => {
            if (cachedResponse) {
              return cachedResponse;
            }
            
            // Fallback para página principal
            if (request.destination === 'document') {
              return caches.match('/');
            }
          });
      })
  );
});
EOF

    # Criar componentes principais
    mkdir -p "$FRONTEND_DIR/src/components/ui"
    
    # Criar main.jsx
    cat > "$FRONTEND_DIR/src/main.jsx" << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

    # Criar index.css
    cat > "$FRONTEND_DIR/src/index.css" << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
 
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
 
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
 
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
 
    --primary: 0 84.2% 60.2%;
    --primary-foreground: 210 40% 98%;
 
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
 
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
 
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
 
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
 
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
 
    --radius: 0.5rem;
  }
 
  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
 
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
 
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
 
    --primary: 0 84.2% 60.2%;
    --primary-foreground: 210 40% 98%;
 
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
 
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
 
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
 
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
 
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}
 
@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF

    # Criar componentes UI básicos
    cat > "$FRONTEND_DIR/src/components/ui/button.jsx" << 'EOF'
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground shadow hover:bg-primary/90",
        destructive:
          "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
        outline:
          "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
        secondary:
          "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-10 rounded-md px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

const Button = React.forwardRef(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
EOF

    # Criar utils.js
    mkdir -p "$FRONTEND_DIR/src/lib"
    cat > "$FRONTEND_DIR/src/lib/utils.js" << 'EOF'
import { clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs) {
  return twMerge(clsx(inputs))
}
EOF

    # Criar App.jsx
    cat > "$FRONTEND_DIR/src/App.jsx" << 'EOF'
import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import './App.css'

function App() {
  const [restaurants, setRestaurants] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    // Simular carregamento de restaurantes
    setTimeout(() => {
      setRestaurants([
        {
          id: 1,
          name: 'Burger King',
          description: 'Hamburgers e lanches rápidos',
          rating: 4.5,
          delivery_time: 30,
          delivery_fee: 5.90,
          is_online: true,
          category: { id: 1, name: 'Lanches' }
        },
        {
          id: 2,
          name: 'Pizza Hut',
          description: 'As melhores pizzas da cidade',
          rating: 4.3,
          delivery_time: 45,
          delivery_fee: 6.90,
          is_online: true,
          category: { id: 2, name: 'Pizza' }
        },
        {
          id: 3,
          name: 'Sushi Japão',
          description: 'Comida japonesa tradicional',
          rating: 4.7,
          delivery_time: 50,
          delivery_fee: 8.90,
          is_online: true,
          category: { id: 3, name: 'Japonesa' }
        }
      ])
      setLoading(false)
    }, 1500)
  }, [])

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <h1 className="text-2xl font-bold text-red-600">DeliveryApp</h1>
            <div className="flex items-center space-x-4">
              <Button variant="ghost" size="sm">
                Entrar
              </Button>
              <Button size="sm" className="bg-red-600 hover:bg-red-700">
                Carrinho
              </Button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Carregando restaurantes...</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {restaurants.map((restaurant) => (
              <div key={restaurant.id} className="bg-white rounded-lg shadow-md overflow-hidden">
                <div className="p-4">
                  <h2 className="text-lg font-semibold">{restaurant.name}</h2>
                  <p className="text-sm text-gray-600">{restaurant.description}</p>
                  <div className="mt-4 flex items-center justify-between text-sm">
                    <div className="flex items-center">
                      <span className="text-yellow-500">★</span>
                      <span className="ml-1">{restaurant.rating}</span>
                    </div>
                    <div>{restaurant.delivery_time} min</div>
                    <div>R$ {restaurant.delivery_fee.toFixed(2)}</div>
                  </div>
                  <Button className="w-full mt-4">Ver Cardápio</Button>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}

export default App
EOF

    # Criar App.css
    cat > "$FRONTEND_DIR/src/App.css" << 'EOF'
/* Estilos personalizados */
.pwa-mode {
  overscroll-behavior-y: none;
}
EOF

    # Criar vite.config.js
    cat > "$FRONTEND_DIR/vite.config.js" << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
EOF

    # Criar tailwind.config.js
    cat > "$FRONTEND_DIR/tailwind.config.js" << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{js,jsx}',
    './components/**/*.{js,jsx}',
    './app/**/*.{js,jsx}',
    './src/**/*.{js,jsx}',
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
EOF

    # Criar postcss.config.js
    cat > "$FRONTEND_DIR/postcss.config.js" << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    # Criar pasta de ícones
    mkdir -p "$FRONTEND_DIR/public/icons"
    
    check_status "Estrutura básica do frontend criada." "Falha ao criar estrutura do frontend."
}

# Configurar frontend
print_status "Configurando frontend..."
cd "$FRONTEND_DIR" || exit 1

# Instalar dependências
pnpm install >> "$LOG_FILE" 2>&1
check_status "Dependências do frontend instaladas." "Falha ao instalar dependências do frontend."

# Criar ícones PWA
print_status "Criando ícones PWA..."
mkdir -p "$FRONTEND_DIR/public/icons"

# Criar ícone SVG base
cat > "$FRONTEND_DIR/public/icons/icon.svg" << 'EOF'
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#dc2626;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#b91c1c;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background -->
  <rect width="512" height="512" rx="80" fill="url(#grad1)"/>
  
  <!-- Delivery Box -->
  <rect x="150" y="180" width="212" height="160" rx="20" fill="white" opacity="0.95"/>
  <rect x="160" y="190" width="192" height="140" rx="15" fill="none" stroke="#dc2626" stroke-width="3" stroke-dasharray="10,5"/>
  
  <!-- Fork and Knife -->
  <g transform="translate(200, 220)">
    <!-- Fork -->
    <path d="M-20 0 L-20 60 M-25 0 L-25 25 M-20 0 L-20 25 M-15 0 L-15 25" stroke="white" stroke-width="4" fill="none" stroke-linecap="round"/>
    
    <!-- Knife -->
    <path d="M20 0 L20 60 M15 0 L25 0 L25 15 L20 15" stroke="white" stroke-width="4" fill="white" stroke-linecap="round"/>
  </g>
  
  <!-- Speed Lines -->
  <g stroke="white" stroke-width="6" stroke-linecap="round" opacity="0.8">
    <line x1="80" y1="120" x2="120" y2="120"/>
    <line x1="90" y1="140" x2="140" y2="140"/>
    <line x1="85" y1="160" x2="125" y2="160"/>
    
    <line x1="380" y1="350" x2="420" y2="350"/>
    <line x1="370" y1="370" x2="420" y2="370"/>
    <line x1="385" y1="390" x2="425" y2="390"/>
  </g>
  
  <!-- App Name -->
  <text x="256" y="450" font-family="Arial, sans-serif" font-size="36" font-weight="bold" text-anchor="middle" fill="white">
    DeliveryApp
  </text>
</svg>
EOF

# Instalar ImageMagick para converter SVG para PNG
apt-get install -y imagemagick >> "$LOG_FILE" 2>&1
check_status "ImageMagick instalado." "Falha ao instalar ImageMagick."

# Converter SVG para PNG em diferentes tamanhos
convert "$FRONTEND_DIR/public/icons/icon.svg" -resize 72x72 "$FRONTEND_DIR/public/icons/icon-72x72.png"
convert "$FRONTEND_DIR/public/icons/icon.svg" -resize 96x96 "$FRONTEND_DIR/public/icons/icon-96x96.png"
convert "$FRONTEND_DIR/public/icons/icon.svg" -resize 128x128 "$FRONTEND_DIR/public/icons/icon-128x128.png"
convert "$FRONTEND_DIR/public/icons/icon.svg" -resize 144x144 "$FRONTEND_DIR/public/icons/icon-144x144.png"
convert "$FRONTEND_DIR/public/icons/icon.svg" -resize 152x152 "$FRONTEND_DIR/public/icons/icon-152x152.png"
convert "$FRONTEND_DIR/public/icons/icon.svg" -resize 192x192 "$FRONTEND_DIR/public/icons/icon-192x192.png"
convert "$FRONTEND_DIR/public/icons/icon.svg" -resize 384x384 "$FRONTEND_DIR/public/icons/icon-384x384.png"
convert "$FRONTEND_DIR/public/icons/icon.svg" -resize 512x512 "$FRONTEND_DIR/public/icons/icon-512x512.png"
check_status "Ícones PWA criados." "Falha ao criar ícones PWA."

# Construir frontend
print_status "Construindo frontend..."
pnpm run build >> "$LOG_FILE" 2>&1
check_status "Frontend construído com sucesso." "Falha ao construir frontend."

# Configurar Nginx
print_status "Configurando Nginx..."

# Criar configuração do Nginx
cat > /etc/nginx/sites-available/deliveryapp << EOF
server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        root $FRONTEND_DIR/dist;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Ativar site
ln -sf /etc/nginx/sites-available/deliveryapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
nginx -t >> "$LOG_FILE" 2>&1
check_status "Configuração do Nginx válida." "Configuração do Nginx inválida. Verifique o log: $LOG_FILE"

# Reiniciar Nginx
systemctl restart nginx
check_status "Nginx reiniciado." "Falha ao reiniciar Nginx."

# Configurar serviço systemd para o backend
print_status "Configurando serviço systemd para o backend..."

cat > /etc/systemd/system/deliveryapp.service << EOF
[Unit]
Description=DeliveryApp Backend
After=network.target postgresql.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/venv/bin"
Environment="FLASK_APP=run.py"
Environment="FLASK_ENV=production"
Environment="DATABASE_URL=postgresql://deliveryapp:deliveryapp123@localhost/deliveryapp"
ExecStart=$BACKEND_DIR/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 run:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd
systemctl daemon-reload

# Iniciar e habilitar serviço
systemctl start deliveryapp
systemctl enable deliveryapp
check_status "Serviço backend iniciado e habilitado." "Falha ao iniciar serviço backend."

# Configurar firewall
print_status "Configurando firewall..."
ufw allow 'Nginx Full'
ufw allow ssh
ufw --force enable
check_status "Firewall configurado." "Falha ao configurar firewall."

# Ajustar permissões
print_status "Ajustando permissões..."
chown -R www-data:www-data "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"
check_status "Permissões ajustadas." "Falha ao ajustar permissões."

# Finalização
clear
echo "================================================================="
echo "                INSTALAÇÃO CONCLUÍDA COM SUCESSO!                 "
echo "================================================================="
echo ""
echo "O DeliveryApp foi instalado e configurado com sucesso!"
echo ""
echo "Você pode acessar o aplicativo em:"
echo "  http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Informações importantes:"
echo "  - Backend API: http://$(hostname -I | awk '{print $1}')/api"
echo "  - Logs do backend: journalctl -u deliveryapp"
echo "  - Logs do Nginx: /var/log/nginx/access.log e error.log"
echo "  - Log de instalação: $LOG_FILE"
echo ""
echo "Para instalar o aplicativo como PWA:"
echo "  1. Acesse o site em um navegador moderno"
echo "  2. Procure pela opção 'Instalar aplicativo' ou similar"
echo "  3. Siga as instruções na tela"
echo ""
echo "================================================================="

log "Instalação concluída com sucesso"
exit 0

