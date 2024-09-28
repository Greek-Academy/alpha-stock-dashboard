import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView
    },
    // TODO: 後ほど変更
    {
      path: '/example',
      name: 'example',
      component: () => import('../views/EchartExample.vue'),
    }
  ]
})

export default router
