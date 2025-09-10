from src.models.user import db
from datetime import datetime

class Order(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    order_number = db.Column(db.String(20), unique=True, nullable=False)
    
    # Relacionamentos
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    restaurant_id = db.Column(db.Integer, db.ForeignKey('restaurant.id'), nullable=False)
    
    # Status do pedido
    status = db.Column(db.String(20), nullable=False, default='pending')  
    # pending, confirmed, preparing, ready, delivering, delivered, cancelled
    
    # Valores
    subtotal = db.Column(db.Float, nullable=False)
    delivery_fee = db.Column(db.Float, nullable=False, default=0.0)
    total = db.Column(db.Float, nullable=False)
    
    # Endereço de entrega
    delivery_street = db.Column(db.String(200), nullable=False)
    delivery_number = db.Column(db.String(20), nullable=False)
    delivery_complement = db.Column(db.String(100), nullable=True)
    delivery_neighborhood = db.Column(db.String(100), nullable=False)
    delivery_city = db.Column(db.String(100), nullable=False)
    delivery_state = db.Column(db.String(50), nullable=False)
    delivery_zip_code = db.Column(db.String(20), nullable=False)
    
    # Informações adicionais
    notes = db.Column(db.Text, nullable=True)
    payment_method = db.Column(db.String(50), nullable=False)  # credit_card, debit_card, pix, cash
    payment_status = db.Column(db.String(20), nullable=False, default='pending')  # pending, paid, failed
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    confirmed_at = db.Column(db.DateTime, nullable=True)
    delivered_at = db.Column(db.DateTime, nullable=True)
    
    # Relacionamentos
    items = db.relationship('OrderItem', backref='order', lazy=True, cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'order_number': self.order_number,
            'user_id': self.user_id,
            'restaurant_id': self.restaurant_id,
            'status': self.status,
            'subtotal': self.subtotal,
            'delivery_fee': self.delivery_fee,
            'total': self.total,
            'delivery_address': {
                'street': self.delivery_street,
                'number': self.delivery_number,
                'complement': self.delivery_complement,
                'neighborhood': self.delivery_neighborhood,
                'city': self.delivery_city,
                'state': self.delivery_state,
                'zip_code': self.delivery_zip_code
            },
            'notes': self.notes,
            'payment_method': self.payment_method,
            'payment_status': self.payment_status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'confirmed_at': self.confirmed_at.isoformat() if self.confirmed_at else None,
            'delivered_at': self.delivered_at.isoformat() if self.delivered_at else None,
            'items': [item.to_dict() for item in self.items]
        }

class OrderItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    
    # Relacionamentos
    order_id = db.Column(db.Integer, db.ForeignKey('order.id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('product.id'), nullable=False)
    
    # Detalhes do item
    quantity = db.Column(db.Integer, nullable=False, default=1)
    unit_price = db.Column(db.Float, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    notes = db.Column(db.Text, nullable=True)  # observações do cliente
    
    # Relacionamentos
    product = db.relationship('Product', backref='order_items')
    
    def to_dict(self):
        return {
            'id': self.id,
            'product_id': self.product_id,
            'quantity': self.quantity,
            'unit_price': self.unit_price,
            'total_price': self.total_price,
            'notes': self.notes,
            'product': self.product.to_dict() if self.product else None
        }

class Review(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    
    # Relacionamentos
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    restaurant_id = db.Column(db.Integer, db.ForeignKey('restaurant.id'), nullable=False)
    order_id = db.Column(db.Integer, db.ForeignKey('order.id'), nullable=True)
    
    # Avaliação
    rating = db.Column(db.Integer, nullable=False)  # 1 a 5
    comment = db.Column(db.Text, nullable=True)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'restaurant_id': self.restaurant_id,
            'order_id': self.order_id,
            'rating': self.rating,
            'comment': self.comment,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class Cart(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    
    # Relacionamentos
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    restaurant_id = db.Column(db.Integer, db.ForeignKey('restaurant.id'), nullable=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relacionamentos
    items = db.relationship('CartItem', backref='cart', lazy=True, cascade='all, delete-orphan')
    
    def to_dict(self):
        total = sum(item.total_price for item in self.items)
        return {
            'id': self.id,
            'user_id': self.user_id,
            'restaurant_id': self.restaurant_id,
            'total': total,
            'items': [item.to_dict() for item in self.items],
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

class CartItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    
    # Relacionamentos
    cart_id = db.Column(db.Integer, db.ForeignKey('cart.id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('product.id'), nullable=False)
    
    # Detalhes do item
    quantity = db.Column(db.Integer, nullable=False, default=1)
    unit_price = db.Column(db.Float, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    notes = db.Column(db.Text, nullable=True)
    
    # Relacionamentos
    product = db.relationship('Product', backref='cart_items')
    
    def to_dict(self):
        return {
            'id': self.id,
            'product_id': self.product_id,
            'quantity': self.quantity,
            'unit_price': self.unit_price,
            'total_price': self.total_price,
            'notes': self.notes,
            'product': self.product.to_dict() if self.product else None
        }

