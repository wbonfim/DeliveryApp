import React, { createContext, useContext, useReducer, useEffect } from 'react';
import apiService from '../services/api';

// Estado inicial
const initialState = {
  user: null,
  isAuthenticated: false,
  cart: null,
  restaurants: [],
  categories: [],
  loading: false,
  error: null,
};

// Tipos de ações
const ActionTypes = {
  SET_LOADING: 'SET_LOADING',
  SET_ERROR: 'SET_ERROR',
  SET_USER: 'SET_USER',
  LOGOUT: 'LOGOUT',
  SET_RESTAURANTS: 'SET_RESTAURANTS',
  SET_CATEGORIES: 'SET_CATEGORIES',
  SET_CART: 'SET_CART',
  ADD_TO_CART: 'ADD_TO_CART',
  REMOVE_FROM_CART: 'REMOVE_FROM_CART',
  CLEAR_CART: 'CLEAR_CART',
};

// Reducer
function appReducer(state, action) {
  switch (action.type) {
    case ActionTypes.SET_LOADING:
      return { ...state, loading: action.payload };
    
    case ActionTypes.SET_ERROR:
      return { ...state, error: action.payload, loading: false };
    
    case ActionTypes.SET_USER:
      return {
        ...state,
        user: action.payload,
        isAuthenticated: !!action.payload,
        loading: false,
        error: null,
      };
    
    case ActionTypes.LOGOUT:
      return {
        ...state,
        user: null,
        isAuthenticated: false,
        cart: null,
        loading: false,
        error: null,
      };
    
    case ActionTypes.SET_RESTAURANTS:
      return { ...state, restaurants: action.payload, loading: false };
    
    case ActionTypes.SET_CATEGORIES:
      return { ...state, categories: action.payload, loading: false };
    
    case ActionTypes.SET_CART:
      return { ...state, cart: action.payload, loading: false };
    
    case ActionTypes.ADD_TO_CART:
      return { ...state, cart: action.payload, loading: false };
    
    case ActionTypes.REMOVE_FROM_CART:
      return { ...state, cart: action.payload, loading: false };
    
    case ActionTypes.CLEAR_CART:
      return { ...state, cart: null, loading: false };
    
    default:
      return state;
  }
}

// Contexto
const AppContext = createContext();

// Provider
export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  // Ações
  const actions = {
    setLoading: (loading) => {
      dispatch({ type: ActionTypes.SET_LOADING, payload: loading });
    },

    setError: (error) => {
      dispatch({ type: ActionTypes.SET_ERROR, payload: error });
    },

    // Autenticação
    login: async (credentials) => {
      try {
        dispatch({ type: ActionTypes.SET_LOADING, payload: true });
        const response = await apiService.login(credentials);
        
        if (response.token) {
          apiService.setToken(response.token);
          dispatch({ type: ActionTypes.SET_USER, payload: response.user });
          await actions.loadCart();
          return response;
        }
      } catch (error) {
        dispatch({ type: ActionTypes.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    register: async (userData) => {
      try {
        dispatch({ type: ActionTypes.SET_LOADING, payload: true });
        const response = await apiService.register(userData);
        dispatch({ type: ActionTypes.SET_USER, payload: response.user });
        return response;
      } catch (error) {
        dispatch({ type: ActionTypes.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    logout: () => {
      apiService.removeToken();
      dispatch({ type: ActionTypes.LOGOUT });
    },

    loadCurrentUser: async () => {
      try {
        if (apiService.token) {
          dispatch({ type: ActionTypes.SET_LOADING, payload: true });
          const response = await apiService.getCurrentUser();
          dispatch({ type: ActionTypes.SET_USER, payload: response.user });
          await actions.loadCart();
        }
      } catch (error) {
        console.error('Erro ao carregar usuário:', error);
        apiService.removeToken();
        dispatch({ type: ActionTypes.LOGOUT });
      }
    },

    // Restaurantes
    loadRestaurants: async (params = {}) => {
      try {
        dispatch({ type: ActionTypes.SET_LOADING, payload: true });
        const response = await apiService.getRestaurants(params);
        dispatch({ type: ActionTypes.SET_RESTAURANTS, payload: response.restaurants });
        return response;
      } catch (error) {
        dispatch({ type: ActionTypes.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    loadCategories: async () => {
      try {
        const response = await apiService.getCategories();
        dispatch({ type: ActionTypes.SET_CATEGORIES, payload: response.categories });
        return response;
      } catch (error) {
        console.error('Erro ao carregar categorias:', error);
      }
    },

    // Carrinho
    loadCart: async () => {
      try {
        if (state.isAuthenticated) {
          const response = await apiService.getCart();
          dispatch({ type: ActionTypes.SET_CART, payload: response.cart });
          return response;
        }
      } catch (error) {
        console.error('Erro ao carregar carrinho:', error);
      }
    },

    addToCart: async (productId, quantity, notes = '') => {
      try {
        dispatch({ type: ActionTypes.SET_LOADING, payload: true });
        const response = await apiService.addToCart(productId, quantity, notes);
        dispatch({ type: ActionTypes.ADD_TO_CART, payload: response.cart });
        return response;
      } catch (error) {
        dispatch({ type: ActionTypes.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    removeFromCart: async (itemId) => {
      try {
        dispatch({ type: ActionTypes.SET_LOADING, payload: true });
        await apiService.removeFromCart(itemId);
        await actions.loadCart();
      } catch (error) {
        dispatch({ type: ActionTypes.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    clearCart: async () => {
      try {
        dispatch({ type: ActionTypes.SET_LOADING, payload: true });
        await apiService.clearCart();
        dispatch({ type: ActionTypes.CLEAR_CART });
      } catch (error) {
        dispatch({ type: ActionTypes.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    // Pedidos
    createOrder: async (orderData) => {
      try {
        dispatch({ type: ActionTypes.SET_LOADING, payload: true });
        const response = await apiService.createOrder(orderData);
        dispatch({ type: ActionTypes.CLEAR_CART });
        return response;
      } catch (error) {
        dispatch({ type: ActionTypes.SET_ERROR, payload: error.message });
        throw error;
      }
    },
  };

  // Carregar dados iniciais
  useEffect(() => {
    actions.loadCurrentUser();
    actions.loadCategories();
  }, []);

  const value = {
    state,
    actions,
  };

  return (
    <AppContext.Provider value={value}>
      {children}
    </AppContext.Provider>
  );
}

// Hook para usar o contexto
export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp deve ser usado dentro de um AppProvider');
  }
  return context;
}

export default AppContext;

