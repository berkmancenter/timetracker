class SuperAction {
  constructor () {
    $('.super-action').each((_idx, el) => {
      this.init_action(el);
    })
  }

  init_action (dom_el) {
    let elem = $(dom_el);

    elem.on('click', () => {
      this.run_action(elem);
    });
  }

  run_action (elem) {
    let action = elem.attr('data-action-url');
    let should_confirm = elem.attr('data-should-confirm');
    let icon = elem.attr('data-icon');
    let confirm_button_text = elem.attr('data-confirm-button-text');
    let confirm_callback = elem.attr('data-confirm-callback');
    let form = elem.parent('form').first();

    form.attr('action', action);

    let confirm_message;
    try {
      confirm_message = document.querySelector(elem.attr('data-confirm-message'));
    } catch (error) {
      confirm_message = elem.attr('data-confirm-message');
    }
    if (typeof confirm_message === 'object') {
      confirm_message = $(confirm_message).html();
    }

    if (should_confirm) {
      Swal.fire({
        html: confirm_message,
        icon: icon || 'question',
        showCancelButton: true,
        confirmButtonText: confirm_button_text || 'Yes',
        confirmButtonColor: '#48c78e',
      }).then((result) => {
        if (result.isConfirmed) {
          if (confirm_callback) {
            eval(confirm_callback);
          }
          form.submit();
        }
      })

      return;
    }

    form.submit();
  }
}

$(document).ready(() => {
  let super_action = new SuperAction();
});
