class Users {
  tables_sorting () {
    $('.users-index-table').tablesorter({
      headers: {
        '.table-actions-column, .table-select-column' : {
          sorter: false
        }
      }
    });
  }

  init () {
    this.tables_sorting();
  }
}

$(document).ready(function() {
  let users = new Users();
  users.init();
});
