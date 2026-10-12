(function () {
  'use strict';

  function showMessage(text, kind) {
    const box = document.querySelector('[data-indent-message]');
    if (!box) return;
    box.textContent = text || '';
    box.className = 'indent-message show ' + (kind === 'success' ? 'success' : 'error');
  }

  async function sendForm(form) {
    const response = await fetch(form.action, {
      method: 'POST',
      body: new URLSearchParams(new FormData(form)),
      headers: { 'X-Requested-With': 'XMLHttpRequest', 'Accept': 'application/json' },
      credentials: 'same-origin'
    });
    let result;
    try { result = await response.json(); }
    catch (_) { throw new Error('The server returned an unexpected response.'); }
    if (!response.ok || result.success !== true) throw new Error(result.message || 'The request could not be completed.');
    return result;
  }

  const itemSelect = document.querySelector('[data-inventory-endpoint]');
  if (itemSelect) {
    const dateInput = document.querySelector('[name="requestDate"]');
    if (dateInput && !dateInput.value) {
      const today = new Date();
      today.setMinutes(today.getMinutes() - today.getTimezoneOffset());
      dateInput.value = today.toISOString().slice(0, 10);
    }
    const url = itemSelect.dataset.inventoryEndpoint;
    fetch(url, { headers: { 'Accept': 'application/json' }, credentials: 'same-origin' })
      .then(response => {
        if (!response.ok) throw new Error('Inventory could not be loaded.');
        return response.json();
      })
      .then(items => {
        itemSelect.innerHTML = '<option value="">Select an item</option>';
        items.forEach(item => {
          const option = document.createElement('option');
          option.value = item.itemId;
          option.textContent = item.itemName + (item.uom ? ' (' + item.uom + ')' : '') + ' · Available: ' + item.availableQuantity + ' · Price: ' + Number(item.price || 0).toFixed(2);
          option.dataset.available = item.availableQuantity;
          itemSelect.appendChild(option);
        });
        itemSelect.disabled = false;
      })
      .catch(error => {
        itemSelect.innerHTML = '<option value="">Inventory unavailable</option>';
        showMessage(error.message, 'error');
      });
  }

  const indentForm = document.querySelector('[data-indent-create]');
  if (indentForm) {
    indentForm.addEventListener('submit', async event => {
      event.preventDefault();
      const item = indentForm.elements.itemId;
      const quantity = Number(indentForm.elements.quantity.value);
      const type = indentForm.elements.indentType.value;
      if (!item.value || !Number.isFinite(quantity) || quantity <= 0) {
        showMessage('Select an item and enter a quantity above zero.', 'error');
        return;
      }
      if (type === 'Issue' && quantity > Number(item.selectedOptions[0].dataset.available || 0)) {
        showMessage('Issue quantity exceeds available stock.', 'error');
        return;
      }
      const button = indentForm.querySelector('[type="submit"]');
      button.disabled = true;
      button.textContent = 'Submitting…';
      try {
        const result = await sendForm(indentForm);
        indentForm.reset();
        showMessage(result.message + (result.indentId ? ' Reference: ' + result.indentId : ''), 'success');
      } catch (error) {
        showMessage(error.message, 'error');
      } finally {
        button.disabled = false;
        button.textContent = 'Submit indent';
      }
    });
  }

  document.querySelectorAll('[data-approval-form]').forEach(form => {
    form.querySelectorAll('[data-decision]').forEach(button => {
      button.addEventListener('click', async () => {
        if (button.dataset.decision === 'Rejected' && !window.confirm('Reject this indent?')) return;
        form.elements.decision.value = button.dataset.decision;
        form.querySelectorAll('button').forEach(control => { control.disabled = true; });
        try {
          const result = await sendForm(form);
          const row = form.closest('tr');
          if (row) row.remove();
          if (!document.querySelector('[data-approval-form]')) {
            const body = document.querySelector('[data-approval-body]');
            if (body) body.innerHTML = '<tr><td class="indent-empty" colspan="7">No indents are waiting for approval.</td></tr>';
          }
          showMessage(result.message, 'success');
        } catch (error) {
          showMessage(error.message, 'error');
          form.querySelectorAll('button').forEach(control => { control.disabled = false; });
        }
      });
    });
  });

  const filter = document.querySelector('[data-indent-filter]');
  if (filter) {
    filter.addEventListener('input', () => {
      const query = filter.value.trim().toLowerCase();
      document.querySelectorAll('[data-indent-row]').forEach(row => {
        row.hidden = !row.dataset.indentRow.toLowerCase().includes(query);
      });
    });
  }
})();
