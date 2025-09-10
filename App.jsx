import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button.jsx'
import { Input } from '@/components/ui/input.jsx'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card.jsx'
import { Badge } from '@/components/ui/badge.jsx'
import { Search, MapPin, Clock, Star, ShoppingCart, User, Menu, Plus } from 'lucide-react'
import { AppProvider, useApp } from './contexts/AppContext'
import AuthModal from './components/AuthModal'
import './App.css'

// Componente principal da aplicação
function DeliveryApp() {
  const { state, actions } = useApp()
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState(null)
  const [showAuthModal, setShowAuthModal] = useState(false)

  // Carregar restaurantes quando o componente monta
  useEffect(() => {
    actions.loadRestaurants()
  }, [])

  // Filtrar restaurantes baseado na busca e categoria
  const filteredRestaurants = state.restaurants.filter(restaurant => {
    const matchesSearch = restaurant.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         restaurant.description.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesCategory = !selectedCategory || 
                           (restaurant.category && restaurant.category.name === selectedCategory)
    return matchesSearch && matchesCategory
  })

  // Função para adicionar ao carrinho
  const handleAddToCart = async (productId) => {
    if (!state.isAuthenticated) {
      setShowAuthModal(true)
      return
    }

    try {
      await actions.addToCart(productId, 1)
      alert('Item adicionado ao carrinho!')
    } catch (error) {
      alert('Erro ao adicionar item ao carrinho: ' + error.message)
    }
  }

  // Obter contagem de itens no carrinho
  const getCartItemCount = () => {
    if (!state.cart || !state.cart.items) return 0
    return state.cart.items.reduce((total, item) => total + item.quantity, 0)
  }

  // Função para abrir restaurante
  const handleOpenRestaurant = (restaurant) => {
    if (!restaurant.is_online) {
      alert('Este restaurante está fechado no momento.')
      return
    }
    
    if (!state.isAuthenticated) {
      setShowAuthModal(true)
      return
    }
    
    // Por enquanto, simular abertura do restaurante
    alert(`Abrindo ${restaurant.name}...\n\nEm breve você poderá ver o cardápio completo e fazer pedidos!`)
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-4">
              <h1 className="text-2xl font-bold text-red-600">DeliveryApp</h1>
              <div className="hidden md:flex items-center space-x-2 text-gray-600">
                <MapPin className="h-4 w-4" />
                <span className="text-sm">São Paulo, SP</span>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              {state.isAuthenticated ? (
                <div className="flex items-center space-x-4">
                  <span className="text-sm text-gray-600">
                    Olá, {state.user?.full_name || state.user?.username}
                  </span>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    onClick={actions.logout}
                  >
                    Sair
                  </Button>
                </div>
              ) : (
                <Button 
                  variant="ghost" 
                  size="sm" 
                  className="hidden md:flex"
                  onClick={() => setShowAuthModal(true)}
                >
                  <User className="h-4 w-4 mr-2" />
                  Entrar
                </Button>
              )}
              
              <Button 
                size="sm" 
                className="bg-red-600 hover:bg-red-700 relative"
                onClick={() => {
                  if (!state.isAuthenticated) {
                    setShowAuthModal(true)
                    return
                  }
                  alert('Carrinho de compras em desenvolvimento!')
                }}
              >
                <ShoppingCart className="h-4 w-4 mr-2" />
                Carrinho
                {getCartItemCount() > 0 && (
                  <Badge className="absolute -top-2 -right-2 bg-yellow-500 text-black text-xs">
                    {getCartItemCount()}
                  </Badge>
                )}
              </Button>
              
              <Button variant="ghost" size="sm" className="md:hidden">
                <Menu className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Search Section */}
      <section className="bg-white py-6 border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="relative max-w-md mx-auto">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
            <Input
              type="text"
              placeholder="Buscar restaurantes ou pratos..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10 pr-4 py-2 w-full"
            />
          </div>
        </div>
      </section>

      {/* Categories */}
      <section className="bg-white py-4 border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-4 overflow-x-auto pb-2">
            <Button
              variant={selectedCategory === null ? "default" : "outline"}
              size="sm"
              onClick={() => setSelectedCategory(null)}
              className="whitespace-nowrap"
            >
              Todos
            </Button>
            {state.categories.map((category) => (
              <Button
                key={category.id}
                variant={selectedCategory === category.name ? "default" : "outline"}
                size="sm"
                onClick={() => setSelectedCategory(category.name)}
                className="whitespace-nowrap"
              >
                {category.name}
              </Button>
            ))}
          </div>
        </div>
      </section>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {state.loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Carregando restaurantes...</p>
          </div>
        ) : (
          <>
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-2">
                {selectedCategory ? `${selectedCategory}` : 'Todos os restaurantes'}
              </h2>
              <p className="text-gray-600">
                {filteredRestaurants.length} restaurante{filteredRestaurants.length !== 1 ? 's' : ''} encontrado{filteredRestaurants.length !== 1 ? 's' : ''}
              </p>
            </div>

            {state.error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
                {state.error}
              </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredRestaurants.map((restaurant) => (
                <Card key={restaurant.id} className="hover:shadow-lg transition-shadow">
                  <div className="relative">
                    <img
                      src={restaurant.image_url || "https://via.placeholder.com/400x300?text=" + encodeURIComponent(restaurant.name)}
                      alt={restaurant.name}
                      className="w-full h-48 object-cover rounded-t-lg"
                    />
                    {restaurant.category && (
                      <Badge className="absolute top-2 right-2 bg-white text-gray-800">
                        {restaurant.category.name}
                      </Badge>
                    )}
                    {!restaurant.is_online && (
                      <div className="absolute inset-0 bg-black bg-opacity-50 rounded-t-lg flex items-center justify-center">
                        <span className="text-white font-semibold">Fechado</span>
                      </div>
                    )}
                  </div>
                  
                  <CardHeader className="pb-2">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-lg">{restaurant.name}</CardTitle>
                      <div className="flex items-center space-x-1">
                        <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                        <span className="text-sm font-medium">{restaurant.rating}</span>
                      </div>
                    </div>
                    <CardDescription className="text-sm">
                      {restaurant.description}
                    </CardDescription>
                  </CardHeader>
                  
                  <CardContent className="pt-0">
                    <div className="flex items-center justify-between text-sm text-gray-600 mb-3">
                      <div className="flex items-center space-x-1">
                        <Clock className="h-4 w-4" />
                        <span>{restaurant.delivery_time} min</span>
                      </div>
                      <div>
                        Entrega: R$ {restaurant.delivery_fee ? restaurant.delivery_fee.toFixed(2) : '0.00'}
                      </div>
                    </div>
                    
                    <Button 
                      className="w-full" 
                      disabled={!restaurant.is_online}
                      onClick={() => handleOpenRestaurant(restaurant)}
                    >
                      {restaurant.is_online ? 'Ver Cardápio' : 'Fechado'}
                    </Button>
                  </CardContent>
                </Card>
              ))}
            </div>

            {filteredRestaurants.length === 0 && !state.loading && (
              <div className="text-center py-12">
                <div className="text-gray-400 text-6xl mb-4">🔍</div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Nenhum restaurante encontrado
                </h3>
                <p className="text-gray-600">
                  Tente buscar por outro termo ou categoria
                </p>
              </div>
            )}
          </>
        )}
      </main>

      {/* Auth Modal */}
      <AuthModal 
        isOpen={showAuthModal} 
        onClose={() => setShowAuthModal(false)} 
      />
    </div>
  )
}

// App wrapper com Provider
function App() {
  return (
    <AppProvider>
      <DeliveryApp />
    </AppProvider>
  )
}

export default App
