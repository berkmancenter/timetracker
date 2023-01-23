class Utils {
  select_all () {
    $('table').on('change', '.table-select-all', (e) => {
      let current_val = $(e.currentTarget).is(":checked");

      $('table input[type=checkbox]').prop('checked', current_val);
    });
  }

  init () {
    this.select_all();
  }
}

$(document).ready(() => {
  let utils = new Utils();
  utils.init();
});