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
      let should_confirm = elem.attr('data-should-confirm');
      let confirm_message = elem.attr('data-confirm-message');
      let form = $('form').first();

      form.attr('action', action);

      if (should_confirm) {
        Swal.fire({
          text: confirm_message,
          icon: 'question',
          showCancelButton: true,
          confirmButtonText: 'Yes',
          confirmButtonColor: '#48c78e',
        }).then((result) => {
          if (result.isConfirmed) {
            form.submit();
          }
        })

        return;
      }

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
