// API Service para conectar com o backend Flask
const API_BASE_URL = 'http://localhost:5000/api';

class ApiService {
  constructor() {
    this.token = localStorage.getItem('token');
  }

  // Configurar token de autenticação
  setToken(token) {
    this.token = token;
    localStorage.setItem('token', token);
  }

  // Remover token
  removeToken() {
    this.token = null;
    localStorage.removeItem('token');
  }

  // Headers padrão para requisições
  getHeaders() {
    const headers = {
      'Content-Type': 'application/json',
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    return headers;
  }

  // Método genérico para fazer requisições
  async request(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const config = {
      headers: this.getHeaders(),
      ...options,
    };

    try {
      const response = await fetch(url, config);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Erro na requisição');
      }

      return data;
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  }

  // Métodos de autenticação
  async login(credentials) {
    return this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
  }

  async register(userData) {
    return this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  }

  async getCurrentUser() {
    return this.request('/auth/me');
  }

  // Métodos de restaurantes
  async getRestaurants(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/restaurants?${queryString}` : '/restaurants';
    return this.request(endpoint);
  }

  async getRestaurant(id) {
    return this.request(`/restaurants/${id}`);
  }

  async getCategories() {
    return this.request('/restaurants/categories');
  }

  // Métodos do carrinho
  async getCart() {
    return this.request('/orders/cart');
  }

  async addToCart(productId, quantity, notes = '') {
    return this.request('/orders/cart/add', {
      method: 'POST',
      body: JSON.stringify({
        product_id: productId,
        quantity,
        notes,
      }),
    });
  }

  async removeFromCart(itemId) {
    return this.request(`/orders/cart/remove/${itemId}`, {
      method: 'DELETE',
    });
  }

  async clearCart() {
    return this.request('/orders/cart/clear', {
      method: 'DELETE',
    });
  }

  // Métodos de pedidos
  async createOrder(orderData) {
    return this.request('/orders', {
      method: 'POST',
      body: JSON.stringify(orderData),
    });
  }

  async getOrders(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = queryString ? `/orders?${queryString}` : '/orders';
    return this.request(endpoint);
  }

  async getOrder(id) {
    return this.request(`/orders/${id}`);
  }

  async updateOrderStatus(id, status) {
    return this.request(`/orders/${id}/status`, {
      method: 'PUT',
      body: JSON.stringify({ status }),
    });
  }

  // Métodos de avaliações
  async createReview(orderId, reviewData) {
    return this.request(`/orders/${orderId}/review`, {
      method: 'POST',
      body: JSON.stringify(reviewData),
    });
  }

  // Health check
  async healthCheck() {
    return this.request('/health');
  }
}

// Instância singleton do serviço de API
const apiService = new ApiService();

export default apiService;

