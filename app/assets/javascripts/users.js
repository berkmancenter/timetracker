class Users {
  select_all () {
    $('.users-index-table').on('change', '.users-select-all', (e) => {
      let current_val = $(e.currentTarget).is(":checked");

      $('table input[type=checkbox]').prop('checked', current_val);
    });
  }

  tables_sorting () {
    $('.users-index-table').tablesorter({
      headers: {
        '.table-actions-column, .table-select-column' : {
          sorter: false
        }
      }
    });
  }

  multi_actions_submit () {
    $('.users-multi-action').on('click', (e) => {
      e.preventDefault();
      let elem = $(e.currentTarget);
      let action = elem.attr('data-action-url');
      let form = $('form').first();

      form.attr('action', action);
      form.submit();
    });
  }

  init () {
    this.select_all();
    this.tables_sorting();
    this.multi_actions_submit();
  }
}

$(document).ready(function() {
  let users = new Users();
  users.init();
});
