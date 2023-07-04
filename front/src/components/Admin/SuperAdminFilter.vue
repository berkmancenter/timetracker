<template>
  <div class="tabs is-toggle is-normal">
    <ul>
      <li v-for="tab in tabs" :key="tab.value" :class="{ 'is-active': activeTab === tab.value }">
        <a @click="setActiveTab(tab.value)">{{ tab.label }}</a>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'SuperAdminFilter',
  props: {
    users: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      tabs: [
        { label: 'Users', value: 'users' },
        { label: 'Admins', value: 'admins' },
        { label: 'All', value: 'all' },
      ],
      activeTab: 'users',
      initialized: false,
    }
  },
  computed: {
    filteredUsers() {
      switch (this.activeTab) {
        case 'users':
          return this.users.filter((user) => !user.superadmin)
        case 'admins':
          return this.users.filter((user) => user.superadmin)
        case 'all':
          return this.users
        default:
          return []
      }
    },
  },
  methods: {
    setActiveTab(tab) {
      this.activeTab = tab
      this.$emit('change', this.filteredUsers)
    },
  },
  watch: {
    users(_newValue, _oldValue) {
      if (this.initialized === false) {
        this.setActiveTab(this.activeTab)
        this.initialized = true
      }
    },
  },
}
</script>
