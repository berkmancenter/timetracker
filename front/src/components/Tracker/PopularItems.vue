<template>
  <div class="tracker-popular">

    <table class="table">
      <tbody>
        <tr>
          <th>{{ title }}</th>
        </tr>
        <tr>
          <td>
            <ul class="tracker-popular-items" v-if="items.length > 0">
              <li v-for="item in items" :key="item" @click="selectItem(item)">
                {{ item }}
              </li>
            </ul>
            <p v-if="items.length === 0">Your most used {{ title.toLowerCase() }} will show up here.</p>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
  export default {
    name: 'PopularItems',
    props: {
      items: {
        type: Object,
        required: true,
      },
      title: {
        type: String,
        required: true,
      },
      type: {
        type: String,
        required: true,
      },
    },
    methods: {
      selectItem(item) {
        this.$store.dispatch('tracker/clearEntryForm')

        this.$store.dispatch('tracker/setFormField', {
          field: this.type,
          value: item,
        })

        this.mitt.emit('popularSelected')
      },
    },
  };
</script>

<style lang="scss">
  .tracker-popular {
    background-color: #ffffff;

    li {
      word-break: break-word;
      padding: 0.2rem 0.3rem;
      margin: 0.4rem;
      border: 0.1rem solid black;
      border-radius: 0.2rem;
      cursor: pointer;

      &:hover {
        background-color: var(--greyish-color);
      }
    }

    ul {
      overflow: auto;
      list-style: none;
      display: flex;
      flex-wrap: wrap;
    }

    user-select: none;
  }
</style>
