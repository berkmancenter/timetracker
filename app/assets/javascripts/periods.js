class Periods {
  datepicker () {
    let datepicker = $('.date-picker').datepicker({
      dateFormat: 'MM dd, yy'
    });

    $('.calendar-entry').off('click');
    $('.calendar-entry').on('click', (ev) => {
      $(ev.currentTarget).prev().focus();
    });
  }

  tables_sorting () {
    $('.periods-index-table, .periods-stats-table, .periods-credits-table').tablesorter({
      headers: {
        '.table-actions-column' : {
          sorter: false
        }
      }
    });
  }

  init () {
    this.datepicker();
    this.tables_sorting();
  }
}

$(document).ready(function() {
  let periods = new Periods();
  periods.init();
});
