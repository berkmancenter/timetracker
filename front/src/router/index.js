import { createRouter, createWebHistory } from 'vue-router'

const basePath = import.meta.env.VITE_BASE_PATH

const router = createRouter({
  history: createWebHistory(basePath || '/'),
  routes: [
    {
      path: '/',
      component: () => import('@/layouts/Default.vue'),
      children: [
        {
          path: '',
          component: () => import('@/components/Tracker/Tracker.vue'),
          name: 'app.index',
        },
        {
          path: ':timesheet?/:month?',
          components: {
            default: () => import('@/components/Tracker/Tracker.vue'),
            Sidebar: () => import('@/components/Tracker/Sidebar.vue'),
          },
          name: 'tracker.index',
        },
        {
          path: 'admin/users',
          components: {
            default: () => import('@/components/Admin/Users/Index.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'users.index',
        },
        {
          path: 'admin/periods',
          components: {
            default: () => import('@/components/Admin/Periods/Index.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.index',
        },
        {
          path: 'admin/periods/new',
          components: {
            default: () => import('@/components/Admin/Periods/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.new',
        },
        {
          path: 'admin/periods/:id/edit',
          components: {
            default: () => import('@/components/Admin/Periods/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.edit',
        },
        {
          path: 'admin/periods/:id/stats',
          components: {
            default: () => import('@/components/Admin/Periods/Stats.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.stats',
        },
        {
          path: 'admin/periods/:id/credits',
          components: {
            default: () => import('@/components/Admin/Periods/Credits.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.credits',
        },
        {
          path: 'admin/timesheets',
          components: {
            default: () => import('@/components/Admin/Timesheets/Index.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.index',
        },
        {
          path: 'admin/timesheets/new',
          components: {
            default: () => import('@/components/Admin/Timesheets/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.new',
        },
        {
          path: 'admin/timesheets/:id/edit',
          components: {
            default: () => import('@/components/Admin/Timesheets/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.edit',
        },
        {
          path: 'admin/timesheets/:id/invite',
          components: {
            default: () => import('@/components/Admin/Timesheets/Invite.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.invite',
        },
        {
          path: 'join/:code',
          components: {
            default: () => import('@/components/Tracker/Join.vue'),
            Sidebar: () => import('@/components/Tracker/Sidebar.vue'),
          },
          name: 'timesheets.join',
        },
      ],
    }
  ]
})

const redirectToSelectedMonth = function(store) {
  router.push(
    {
      name: 'tracker.index',
      params: {
        timesheet: store.state.tracker.selectedTimesheet.uuid,
        month: store.state.tracker.selectedMonth,
      },
    },
  )
}

export { router, redirectToSelectedMonth }
