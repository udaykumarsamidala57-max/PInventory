<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
const o = document.createElement('option');
o.value = i.name;
o.text = i.name;
o.dataset.id = i.id;
o.dataset.uom = i.UOM;
o.dataset.stock = i.stock;
itemSel.add(o);
});
};


itemSel.onchange = () => {
const opt = itemSel.options[itemSel.selectedIndex];
uomCell.textContent = opt ? opt.dataset.uom || '' : '';
stockCell.textContent = opt ? opt.dataset.stock || '0' : '0';
};
}


function restrictDateToToday() {
const today = new Date().toISOString().split('T')[0];
const dateField = document.getElementById("dateField");
dateField.value = today;
dateField.min = today;
dateField.max = today;
}


// Helper to parse float safely
function toFloat(v) {
const n = parseFloat(v);
return isNaN(n) ? 0 : n;
}


// On submit: client-side validation including stock check for Issue type
document.getElementById('indentForm').addEventListener('submit', function(event) {
const ids = [], names = [], qtys = [], purps = [], uomsArr = [];


let invalid = false;
const requestType = document.querySelector('input[name="purchaseOrIssue"]:checked').value;


document.querySelectorAll("#itemsTable tbody tr").forEach(tr => {
const sel = tr.querySelector(".item");
const opt = sel.options[sel.selectedIndex];
const stock = toFloat(opt ? opt.dataset.stock || "0" : "0");
const qty = toFloat(tr.querySelector(".qty").value || "0");


// If Issue: stock must be >= qty unless stock == 0 (means not tracked) -> but now user requested: if Issue and stock==0 -> not available
if (requestType === 'Issue') {
if (stock <= 0) {
alert(`Stock not available for item: ${opt ? opt.value : ''}`);
invalid = true;
return;
}
if (qty > stock) {
alert(`Please request only up to the available quantity for ${opt ? opt.value : ''}.\nAvailable: ${stock}`);
invalid = true;
return;
}
}


ids.push(opt ? opt.dataset.id : "");
names.push(opt ? opt.value : "");
qtys.push(qty);
purps.push(tr.querySelector(".purpose").value);
uomsArr.push(tr.querySelector(".uom").textContent);
});


if (invalid) {
event.preventDefault();
return false;
}


if (ids.length === 0) {
alert('Please add at least one item.');
event.preventDefault();
return false;
}


this.itemIds.value = ids.join(",");
this.itemNames.value = names.join(",");
this.quantities.value = qtys.join(",");
this.purposes.value = purps.join(",");
this.uoms.value = uomsArr.join(",");
});
</script>


</body>
</html>