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

  init () {
    this.datepicker();
  }
}

$(document).ready(function() {
  let periods = new Periods();
  periods.init();
});
