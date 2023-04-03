<template>
  <div>
    <h5 class="has-text-weight-bold is-size-5 mt-2 sidebar-header">Popular</h5>

    <popular-items title="Categories" type="category" :items="$store.state.tracker.popular.categories"></popular-items>
    <popular-items title="Projects" type="project" :items="$store.state.tracker.popular.projects"></popular-items>
  </div>
</template>

<script>
  import PopularItems from './PopularItems.vue'

  export default {
    name: 'Popular',
    components: {
      PopularItems,
    },
  }
</script>
