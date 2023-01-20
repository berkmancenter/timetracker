class Periods {
  datepicker () {
    let datepicker = $('.date-picker').datepicker({
      dateFormat: 'MM dd, yy'
    });

    $('#calendar-entry').off('click');

    $('#calendar-entry').on('click', () => {
      datepicker.focus();
    });
  }

  tables_sorting () {
    $('.periods-index-table, .periods-stats-table').tablesorter({
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
