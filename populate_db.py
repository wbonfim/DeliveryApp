#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from src.models.user import db, User, Address
from src.models.restaurant import Category, Restaurant, ProductCategory, Product
from src.models.order import Order, OrderItem, Review
from src.main import app

def populate_database():
    with app.app_context():
        # Limpar dados existentes
        db.drop_all()
        db.create_all()
        
        print("Criando categorias...")
        # Criar categorias
        categories = [
            Category(name="Lanches", description="Hambúrgueres, sanduíches e lanches", image_url="https://via.placeholder.com/300x200?text=Lanches"),
            Category(name="Pizza", description="Pizzas tradicionais e especiais", image_url="https://via.placeholder.com/300x200?text=Pizza"),
            Category(name="Japonesa", description="Sushi, sashimi e comida japonesa", image_url="https://via.placeholder.com/300x200?text=Japonesa"),
            Category(name="Italiana", description="Massas, risotos e pratos italianos", image_url="https://via.placeholder.com/300x200?text=Italiana"),
            Category(name="Brasileira", description="Pratos típicos brasileiros", image_url="https://via.placeholder.com/300x200?text=Brasileira"),
            Category(name="Doces", description="Sobremesas, bolos e doces", image_url="https://via.placeholder.com/300x200?text=Doces"),
            Category(name="Bebidas", description="Refrigerantes, sucos e bebidas", image_url="https://via.placeholder.com/300x200?text=Bebidas")
        ]
        
        for category in categories:
            db.session.add(category)
        
        db.session.commit()
        
        print("Criando usuários...")
        # Criar usuários de teste
        users = [
            User(username="admin", email="admin@delivery.com", full_name="Administrador", user_type="admin"),
            User(username="cliente1", email="cliente1@email.com", full_name="João Silva", user_type="customer", phone="(11) 99999-1111"),
            User(username="cliente2", email="cliente2@email.com", full_name="Maria Santos", user_type="customer", phone="(11) 99999-2222"),
            User(username="restaurante1", email="restaurante1@email.com", full_name="Dono do Burger King", user_type="restaurant", phone="(11) 99999-3333"),
            User(username="restaurante2", email="restaurante2@email.com", full_name="Dono da Pizzaria", user_type="restaurant", phone="(11) 99999-4444"),
        ]
        
        for user in users:
            user.set_password("123456")
            db.session.add(user)
        
        db.session.commit()
        
        # Buscar usuários criados
        admin = User.query.filter_by(username="admin").first()
        cliente1 = User.query.filter_by(username="cliente1").first()
        cliente2 = User.query.filter_by(username="cliente2").first()
        restaurante1 = User.query.filter_by(username="restaurante1").first()
        restaurante2 = User.query.filter_by(username="restaurante2").first()
        
        # Buscar categorias
        cat_lanches = Category.query.filter_by(name="Lanches").first()
        cat_pizza = Category.query.filter_by(name="Pizza").first()
        cat_japonesa = Category.query.filter_by(name="Japonesa").first()
        cat_italiana = Category.query.filter_by(name="Italiana").first()
        cat_doces = Category.query.filter_by(name="Doces").first()
        
        print("Criando endereços...")
        # Criar endereços para clientes
        addresses = [
            Address(user_id=cliente1.id, street="Rua das Flores", number="123", 
                   neighborhood="Centro", city="São Paulo", state="SP", zip_code="01000-000", is_default=True),
            Address(user_id=cliente2.id, street="Av. Paulista", number="1000", 
                   neighborhood="Bela Vista", city="São Paulo", state="SP", zip_code="01310-000", is_default=True)
        ]
        
        for address in addresses:
            db.session.add(address)
        
        db.session.commit()
        
        print("Criando restaurantes...")
        # Criar restaurantes
        restaurants = [
            Restaurant(
                name="Burger Palace",
                description="Os melhores hambúrgueres da cidade com ingredientes frescos e selecionados",
                image_url="https://via.placeholder.com/400x300?text=Burger+Palace",
                cover_image_url="https://via.placeholder.com/800x400?text=Burger+Palace+Cover",
                phone="(11) 3333-1111",
                email="contato@burgerpalace.com",
                street="Rua dos Hambúrgueres",
                number="100",
                neighborhood="Vila Madalena",
                city="São Paulo",
                state="SP",
                zip_code="05433-000",
                delivery_fee=5.90,
                minimum_order=25.00,
                delivery_time=35,
                rating=4.5,
                total_reviews=150,
                category_id=cat_lanches.id,
                owner_id=restaurante1.id
            ),
            Restaurant(
                name="Pizzaria Bella Napoli",
                description="Pizzas artesanais com massa fina e ingredientes importados da Itália",
                image_url="https://via.placeholder.com/400x300?text=Bella+Napoli",
                cover_image_url="https://via.placeholder.com/800x400?text=Bella+Napoli+Cover",
                phone="(11) 3333-2222",
                email="contato@bellanapoli.com",
                street="Rua da Pizza",
                number="200",
                neighborhood="Moema",
                city="São Paulo",
                state="SP",
                zip_code="04567-000",
                delivery_fee=7.50,
                minimum_order=30.00,
                delivery_time=45,
                rating=4.8,
                total_reviews=200,
                category_id=cat_pizza.id,
                owner_id=restaurante2.id
            ),
            Restaurant(
                name="Sushi Zen",
                description="Culinária japonesa autêntica com peixes frescos e pratos tradicionais",
                image_url="https://via.placeholder.com/400x300?text=Sushi+Zen",
                cover_image_url="https://via.placeholder.com/800x400?text=Sushi+Zen+Cover",
                phone="(11) 3333-3333",
                email="contato@sushizen.com",
                street="Rua Japão",
                number="300",
                neighborhood="Liberdade",
                city="São Paulo",
                state="SP",
                zip_code="01503-000",
                delivery_fee=8.90,
                minimum_order=40.00,
                delivery_time=40,
                rating=4.7,
                total_reviews=120,
                category_id=cat_japonesa.id,
                owner_id=admin.id
            ),
            Restaurant(
                name="Pasta & Amore",
                description="Massas frescas e molhos especiais da tradição italiana",
                image_url="https://via.placeholder.com/400x300?text=Pasta+Amore",
                cover_image_url="https://via.placeholder.com/800x400?text=Pasta+Amore+Cover",
                phone="(11) 3333-4444",
                email="contato@pastaamore.com",
                street="Rua Itália",
                number="400",
                neighborhood="Bixiga",
                city="São Paulo",
                state="SP",
                zip_code="01327-000",
                delivery_fee=6.50,
                minimum_order=28.00,
                delivery_time=30,
                rating=4.6,
                total_reviews=180,
                category_id=cat_italiana.id,
                owner_id=admin.id
            ),
            Restaurant(
                name="Doce Tentação",
                description="Bolos, tortas e sobremesas irresistíveis feitas com muito carinho",
                image_url="https://via.placeholder.com/400x300?text=Doce+Tentacao",
                cover_image_url="https://via.placeholder.com/800x400?text=Doce+Tentacao+Cover",
                phone="(11) 3333-5555",
                email="contato@docetentacao.com",
                street="Rua dos Doces",
                number="500",
                neighborhood="Jardins",
                city="São Paulo",
                state="SP",
                zip_code="01404-000",
                delivery_fee=4.90,
                minimum_order=20.00,
                delivery_time=25,
                rating=4.9,
                total_reviews=300,
                category_id=cat_doces.id,
                owner_id=admin.id
            )
        ]
        
        for restaurant in restaurants:
            db.session.add(restaurant)
        
        db.session.commit()
        
        # Buscar restaurantes criados
        burger_palace = Restaurant.query.filter_by(name="Burger Palace").first()
        bella_napoli = Restaurant.query.filter_by(name="Pizzaria Bella Napoli").first()
        sushi_zen = Restaurant.query.filter_by(name="Sushi Zen").first()
        pasta_amore = Restaurant.query.filter_by(name="Pasta & Amore").first()
        doce_tentacao = Restaurant.query.filter_by(name="Doce Tentação").first()
        
        print("Criando categorias de produtos...")
        # Criar categorias de produtos para cada restaurante
        product_categories = [
            # Burger Palace
            ProductCategory(name="Hambúrgueres", restaurant_id=burger_palace.id, order=1),
            ProductCategory(name="Acompanhamentos", restaurant_id=burger_palace.id, order=2),
            ProductCategory(name="Bebidas", restaurant_id=burger_palace.id, order=3),
            
            # Bella Napoli
            ProductCategory(name="Pizzas Doces", restaurant_id=bella_napoli.id, order=1),
            ProductCategory(name="Pizzas Salgadas", restaurant_id=bella_napoli.id, order=2),
            ProductCategory(name="Calzones", restaurant_id=bella_napoli.id, order=3),
            
            # Sushi Zen
            ProductCategory(name="Sushi", restaurant_id=sushi_zen.id, order=1),
            ProductCategory(name="Sashimi", restaurant_id=sushi_zen.id, order=2),
            ProductCategory(name="Hot Rolls", restaurant_id=sushi_zen.id, order=3),
            ProductCategory(name="Temaki", restaurant_id=sushi_zen.id, order=4),
            
            # Pasta & Amore
            ProductCategory(name="Massas", restaurant_id=pasta_amore.id, order=1),
            ProductCategory(name="Risotos", restaurant_id=pasta_amore.id, order=2),
            ProductCategory(name="Saladas", restaurant_id=pasta_amore.id, order=3),
            
            # Doce Tentação
            ProductCategory(name="Bolos", restaurant_id=doce_tentacao.id, order=1),
            ProductCategory(name="Tortas", restaurant_id=doce_tentacao.id, order=2),
            ProductCategory(name="Sobremesas", restaurant_id=doce_tentacao.id, order=3)
        ]
        
        for cat in product_categories:
            db.session.add(cat)
        
        db.session.commit()
        
        print("Criando produtos...")
        # Buscar categorias de produtos
        burger_hamburgueres = ProductCategory.query.filter_by(name="Hambúrgueres", restaurant_id=burger_palace.id).first()
        burger_acompanhamentos = ProductCategory.query.filter_by(name="Acompanhamentos", restaurant_id=burger_palace.id).first()
        burger_bebidas = ProductCategory.query.filter_by(name="Bebidas", restaurant_id=burger_palace.id).first()
        
        pizza_doces = ProductCategory.query.filter_by(name="Pizzas Doces", restaurant_id=bella_napoli.id).first()
        pizza_salgadas = ProductCategory.query.filter_by(name="Pizzas Salgadas", restaurant_id=bella_napoli.id).first()
        
        sushi_sushi = ProductCategory.query.filter_by(name="Sushi", restaurant_id=sushi_zen.id).first()
        sushi_sashimi = ProductCategory.query.filter_by(name="Sashimi", restaurant_id=sushi_zen.id).first()
        sushi_hot = ProductCategory.query.filter_by(name="Hot Rolls", restaurant_id=sushi_zen.id).first()
        
        pasta_massas = ProductCategory.query.filter_by(name="Massas", restaurant_id=pasta_amore.id).first()
        pasta_risotos = ProductCategory.query.filter_by(name="Risotos", restaurant_id=pasta_amore.id).first()
        
        doce_bolos = ProductCategory.query.filter_by(name="Bolos", restaurant_id=doce_tentacao.id).first()
        doce_tortas = ProductCategory.query.filter_by(name="Tortas", restaurant_id=doce_tentacao.id).first()
        
        # Criar produtos
        products = [
            # Burger Palace
            Product(name="Big Burger", description="Hambúrguer duplo com queijo, alface, tomate e molho especial", 
                   price=24.90, restaurant_id=burger_palace.id, category_id=burger_hamburgueres.id,
                   image_url="https://via.placeholder.com/300x200?text=Big+Burger"),
            Product(name="Chicken Burger", description="Hambúrguer de frango grelhado com maionese temperada", 
                   price=19.90, restaurant_id=burger_palace.id, category_id=burger_hamburgueres.id,
                   image_url="https://via.placeholder.com/300x200?text=Chicken+Burger"),
            Product(name="Veggie Burger", description="Hambúrguer vegetariano com quinoa e legumes", 
                   price=22.90, restaurant_id=burger_palace.id, category_id=burger_hamburgueres.id,
                   image_url="https://via.placeholder.com/300x200?text=Veggie+Burger"),
            Product(name="Batata Frita", description="Batatas fritas crocantes temperadas", 
                   price=12.90, restaurant_id=burger_palace.id, category_id=burger_acompanhamentos.id,
                   image_url="https://via.placeholder.com/300x200?text=Batata+Frita"),
            Product(name="Onion Rings", description="Anéis de cebola empanados e fritos", 
                   price=14.90, restaurant_id=burger_palace.id, category_id=burger_acompanhamentos.id,
                   image_url="https://via.placeholder.com/300x200?text=Onion+Rings"),
            Product(name="Coca-Cola", description="Refrigerante Coca-Cola 350ml", 
                   price=5.90, restaurant_id=burger_palace.id, category_id=burger_bebidas.id,
                   image_url="https://via.placeholder.com/300x200?text=Coca+Cola"),
            
            # Bella Napoli
            Product(name="Pizza Margherita", description="Molho de tomate, mussarela, manjericão e azeite", 
                   price=32.90, restaurant_id=bella_napoli.id, category_id=pizza_salgadas.id,
                   image_url="https://via.placeholder.com/300x200?text=Pizza+Margherita"),
            Product(name="Pizza Pepperoni", description="Molho de tomate, mussarela e pepperoni", 
                   price=36.90, restaurant_id=bella_napoli.id, category_id=pizza_salgadas.id,
                   image_url="https://via.placeholder.com/300x200?text=Pizza+Pepperoni"),
            Product(name="Pizza Quatro Queijos", description="Mussarela, gorgonzola, parmesão e provolone", 
                   price=38.90, restaurant_id=bella_napoli.id, category_id=pizza_salgadas.id,
                   image_url="https://via.placeholder.com/300x200?text=Pizza+4+Queijos"),
            Product(name="Pizza Chocolate", description="Chocolate ao leite com morangos", 
                   price=29.90, restaurant_id=bella_napoli.id, category_id=pizza_doces.id,
                   image_url="https://via.placeholder.com/300x200?text=Pizza+Chocolate"),
            
            # Sushi Zen
            Product(name="Combo Sushi 20 peças", description="Variado com salmão, atum e peixe branco", 
                   price=45.90, restaurant_id=sushi_zen.id, category_id=sushi_sushi.id,
                   image_url="https://via.placeholder.com/300x200?text=Combo+Sushi"),
            Product(name="Sashimi Salmão", description="8 fatias de salmão fresco", 
                   price=28.90, restaurant_id=sushi_zen.id, category_id=sushi_sashimi.id,
                   image_url="https://via.placeholder.com/300x200?text=Sashimi+Salmao"),
            Product(name="Hot Philadelphia", description="Salmão, cream cheese e cebolinha", 
                   price=24.90, restaurant_id=sushi_zen.id, category_id=sushi_hot.id,
                   image_url="https://via.placeholder.com/300x200?text=Hot+Philadelphia"),
            
            # Pasta & Amore
            Product(name="Spaghetti Carbonara", description="Massa com bacon, ovos, queijo e pimenta", 
                   price=26.90, restaurant_id=pasta_amore.id, category_id=pasta_massas.id,
                   image_url="https://via.placeholder.com/300x200?text=Spaghetti+Carbonara"),
            Product(name="Lasanha Bolonhesa", description="Lasanha tradicional com molho bolonhesa", 
                   price=29.90, restaurant_id=pasta_amore.id, category_id=pasta_massas.id,
                   image_url="https://via.placeholder.com/300x200?text=Lasanha+Bolonhesa"),
            Product(name="Risotto de Camarão", description="Risotto cremoso com camarões grelhados", 
                   price=34.90, restaurant_id=pasta_amore.id, category_id=pasta_risotos.id,
                   image_url="https://via.placeholder.com/300x200?text=Risotto+Camarao"),
            
            # Doce Tentação
            Product(name="Bolo de Chocolate", description="Bolo de chocolate com cobertura de brigadeiro", 
                   price=18.90, restaurant_id=doce_tentacao.id, category_id=doce_bolos.id,
                   image_url="https://via.placeholder.com/300x200?text=Bolo+Chocolate"),
            Product(name="Torta de Morango", description="Torta com creme e morangos frescos", 
                   price=22.90, restaurant_id=doce_tentacao.id, category_id=doce_tortas.id,
                   image_url="https://via.placeholder.com/300x200?text=Torta+Morango"),
            Product(name="Cheesecake", description="Cheesecake cremoso com calda de frutas vermelhas", 
                   price=16.90, restaurant_id=doce_tentacao.id, category_id=doce_tortas.id,
                   image_url="https://via.placeholder.com/300x200?text=Cheesecake")
        ]
        
        for product in products:
            db.session.add(product)
        
        db.session.commit()
        
        print("Banco de dados populado com sucesso!")
        print("\nUsuários criados:")
        print("- admin / admin@delivery.com (senha: 123456)")
        print("- cliente1 / cliente1@email.com (senha: 123456)")
        print("- cliente2 / cliente2@email.com (senha: 123456)")
        print("- restaurante1 / restaurante1@email.com (senha: 123456)")
        print("- restaurante2 / restaurante2@email.com (senha: 123456)")
        print(f"\nCategorias criadas: {len(categories)}")
        print(f"Restaurantes criados: {len(restaurants)}")
        print(f"Produtos criados: {len(products)}")

if __name__ == "__main__":
    populate_database()

