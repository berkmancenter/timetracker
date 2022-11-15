function user_toggle () {
  if ($('#user-chooser-toggle')) {
    $('#user-chooser-toggle').off('click');

    $('#user-chooser-toggle').on('click', function() {
      $('#sudo').toggle();
    });
  }
}

function entry_form () {
  let form_selector = '.new_time_entry';
  if ($('#time_entry_id').val()) {
    form_selector = '.edit_time_entry';
  }

  $(document).off('submit', form_selector);

  $(document).on('submit', form_selector, e => {
    e.preventDefault();

    $('#loader').show();

    $.post(timetracker_edit_path, $(form_selector).serialize())
      .done(
        (response) => {
          $('#entries').html(response);
        }
      )
      .fail(
        (response) => {
          $('#new-entry-error').html(response);
        }
      )
      .always(
        (response) => {
          $('#loader').hide();
          init();
        }
      )
  });

}

function entry_actions () {
  $(document).off('click', '.entry-clone');
  $(document).on('click', '.entry-clone', (e) => {
    e.preventDefault();

    $.get(e.currentTarget.href)
      .done(
        (response) => {
          $('#entries').html(response);
          init();
        }
      )
  });

  $('#dialog-confirm-delete').dialog({
    autoOpen: false,
    resizable: false,
    draggable: false,
    height: 'auto',
    width: 400,
    modal: true,
    buttons: {
      'Delete': function() {
        console.log($('#dialog-confirm-delete').data('current-url'));
        $.get($('#dialog-confirm-delete').data('current-url'))
          .done(
            (response) => {
              $(this).dialog('close');
              $('#entries').html(response);
              init();
            }
          )
      },
      Cancel: function() {
        $(this).dialog('close');
      }
    }
  });

  $(document).off('click', '.entry-delete');
  $(document).on('click', '.entry-delete', (e) => {
    e.preventDefault();

    $('#dialog-confirm-delete').data('current-url', e.currentTarget.href);
    $('#dialog-confirm-delete').dialog('open');
  });

  $(document).off('click', '.entry-edit');
  $(document).on('click', '.entry-edit', (e) => {
    e.preventDefault();

    $.get(e.currentTarget.href)
      .done(
        (response) => {
          $('#entry-form').html(response);
          init();
        }
      )
  });
}

function datepicker () {
  let datepicker = $('#time_entry_entry_date').datepicker({
    dateFormat: 'MM dd, yy'
  });

  $('#calendar-entry').off('click');

  $('#calendar-entry').on('click', () => {
    datepicker.focus();
  });
}

function update_content (element_selector, url, params) {
  $.get(`${url}?${params}`)
    .done(
      (response) => {
        $(element_selector).html(response);
      }
    )
}

function auto_complete () {
  $('#time_entry_category').autocomplete({
    source: `${timetracker_autocomplete}?field=category`,
    minLength: 2
  });

  $('#time_entry_project').autocomplete({
    source: `${timetracker_autocomplete}?field=project`,
    minLength: 2
  });
}

function mobile_menu () {
  $('.navbar-burger').off('click');
  $('.navbar-burger').on('click', () => {
    $('.navbar-burger').toggleClass('is-active');
    $('.navbar-menu').toggleClass('is-active');
  });
}

function flash () {
  $('.notification .delete').off('click');
  $('.notification .delete').on('click', (e) => {
    $(e.currentTarget).parent().remove();
  });
}

function month_change () {
  $(document).off('click', '#month-change');
  $(document).on('click', '#month-change', (e) => {
    window.location = `${timetracker_root_path}?month=${$('#selected-month').val()}`;
  });

  $(document).off('click', '#month-csv');
  $(document).on('click', '#month-csv', (e) => {
    window.location = `${timetracker_root_path}?month=${$('#selected-month').val()}&csv=1`;
  });
}

function init () {
  user_toggle();
  entry_form();
  entry_actions();
  datepicker();
  auto_complete();
  mobile_menu();
  flash();
  month_change();
}

$(document).ready(function() {
  init();
});
