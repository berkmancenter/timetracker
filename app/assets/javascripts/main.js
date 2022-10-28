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
  let actions = ['clone', 'delete'];

  actions.forEach((action) => {
    $(document).off('click', `.entry-${action}`);

    $(document).on('click', `.entry-${action}`, (e) => {
      e.preventDefault();

      $.get(e.currentTarget.href)
        .done(
          (response) => {
            $('#entries').html(response);
            init();
          }
        )
    });
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

function init_datepicker () {
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
  console.log(`${timetracker_autocomplete}?field=category`);
  $('#time_entry_category').autocomplete({
    source: `${timetracker_autocomplete}?field=category`,
    minLength: 2
  });

  $('#time_entry_project').autocomplete({
    source: `${timetracker_autocomplete}?field=project`,
    minLength: 2
  });
}

function init () {
  user_toggle();
  entry_form();
  entry_actions();
  init_datepicker();
  auto_complete();
}

$(document).ready(function() {
  init();
});
