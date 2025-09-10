from src.models.user import db
from datetime import datetime

class Category(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    image_url = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relacionamentos
    restaurants = db.relationship('Restaurant', backref='category', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'image_url': self.image_url,
            'is_active': self.is_active
        }

class Restaurant(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    image_url = db.Column(db.String(255), nullable=True)
    cover_image_url = db.Column(db.String(255), nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    email = db.Column(db.String(120), nullable=True)
    
    # Endereço
    street = db.Column(db.String(200), nullable=False)
    number = db.Column(db.String(20), nullable=False)
    complement = db.Column(db.String(100), nullable=True)
    neighborhood = db.Column(db.String(100), nullable=False)
    city = db.Column(db.String(100), nullable=False)
    state = db.Column(db.String(50), nullable=False)
    zip_code = db.Column(db.String(20), nullable=False)
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    
    # Configurações operacionais
    is_online = db.Column(db.Boolean, default=True)
    is_active = db.Column(db.Boolean, default=True)
    delivery_fee = db.Column(db.Float, default=0.0)
    minimum_order = db.Column(db.Float, default=0.0)
    delivery_time = db.Column(db.Integer, default=30)  # em minutos
    rating = db.Column(db.Float, default=0.0)
    total_reviews = db.Column(db.Integer, default=0)
    
    # Relacionamentos
    category_id = db.Column(db.Integer, db.ForeignKey('category.id'), nullable=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    products = db.relationship('Product', backref='restaurant', lazy=True)
    orders = db.relationship('Order', backref='restaurant', lazy=True)
    reviews = db.relationship('Review', backref='restaurant', lazy=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'image_url': self.image_url,
            'cover_image_url': self.cover_image_url,
            'phone': self.phone,
            'email': self.email,
            'address': {
                'street': self.street,
                'number': self.number,
                'complement': self.complement,
                'neighborhood': self.neighborhood,
                'city': self.city,
                'state': self.state,
                'zip_code': self.zip_code,
                'latitude': self.latitude,
                'longitude': self.longitude
            },
            'is_online': self.is_online,
            'is_active': self.is_active,
            'delivery_fee': self.delivery_fee,
            'minimum_order': self.minimum_order,
            'delivery_time': self.delivery_time,
            'rating': self.rating,
            'total_reviews': self.total_reviews,
            'category_id': self.category_id,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class ProductCategory(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    restaurant_id = db.Column(db.Integer, db.ForeignKey('restaurant.id'), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    order = db.Column(db.Integer, default=0)
    
    # Relacionamentos
    products = db.relationship('Product', backref='product_category', lazy=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'restaurant_id': self.restaurant_id,
            'is_active': self.is_active,
            'order': self.order
        }

class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    price = db.Column(db.Float, nullable=False)
    image_url = db.Column(db.String(255), nullable=True)
    is_available = db.Column(db.Boolean, default=True)
    is_active = db.Column(db.Boolean, default=True)
    preparation_time = db.Column(db.Integer, default=15)  # em minutos
    
    # Relacionamentos
    restaurant_id = db.Column(db.Integer, db.ForeignKey('restaurant.id'), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('product_category.id'), nullable=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'price': self.price,
            'image_url': self.image_url,
            'is_available': self.is_available,
            'is_active': self.is_active,
            'preparation_time': self.preparation_time,
            'restaurant_id': self.restaurant_id,
            'category_id': self.category_id,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

