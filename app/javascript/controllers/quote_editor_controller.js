import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "row", "rowTemplate", "editor", "itemName", "quantity", "unitPrice", "vat", "previewVat", "previewTtc", "editButton", "deleteButton", "addButton", "totalHt", "totalVat", "totalTtc"]
  static values = { warning: String }

  connect() {
    this.dirty = false
    this.editingRow = null
    this.nextIndex = Math.max(-1, ...this.rowTargets.map((row) => Number(row.dataset.index))) + 1
    this.beforeUnload = (event) => {
      if (!this.dirty) return
      event.preventDefault()
      event.returnValue = this.warningValue
    }
    this.beforeVisit = (event) => {
      if (!this.dirty || window.confirm(this.warningValue)) {
        this.dirty = false
        return
      }
      event.preventDefault()
    }
    window.addEventListener("beforeunload", this.beforeUnload)
    document.addEventListener("turbo:before-visit", this.beforeVisit)
      ;[this.quantityTarget, this.unitPriceTarget, this.vatTarget].forEach((input) => input.addEventListener("input", () => this.updatePreview()))
    this.rowTargets.forEach((row) => this.renderRow(row))
    this.updateTotals()
    if (this.editorTarget.classList.contains("hidden")) {
      this.toggleEditorInputs(true)
    } else {
      this.prepareEmptyEditor()
    }
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnload)
    document.removeEventListener("turbo:before-visit", this.beforeVisit)
  }

  markDirty() { this.dirty = true }

  add() {
    this.editingRow = null
    this.itemNameTarget.value = ""
    this.quantityTarget.value = 1
    this.unitPriceTarget.value = ""
    this.vatTarget.value = "20"
    this.itemsTarget.append(this.editorTarget)
    this.openEditor()
  }

  edit(event) {
    const row = event.currentTarget.closest('[data-quote-editor-target~="row"]')
    this.editingRow = row
    this.itemNameTarget.value = row.dataset.name
    this.quantityTarget.value = row.dataset.quantity
    this.unitPriceTarget.value = (Number(row.dataset.unitPrice) / 100).toFixed(2)
    this.vatTarget.value = row.dataset.vat
    row.after(this.editorTarget)
    row.classList.add("hidden")
    row.classList.remove("table-row")
    this.openEditor()
  }

  openEditor() {
    this.editorTarget.classList.remove("hidden")
    this.editorTarget.classList.add("table-row")
    this.toggleEditorInputs(false)
    this.toggleActions(true)
    this.updatePreview()
    this.itemNameTarget.focus()
  }

  cancel() {
    if (this.activeRows().length === 0) {
      this.prepareEmptyEditor()
      return
    }
    if (this.editingRow) {
      this.editingRow.classList.remove("hidden")
      this.editingRow.classList.add("table-row")
    }
    this.hideEditor()
    this.editingRow = null
    this.toggleActions(false)
  }

  saveItem() { this.commitEditor() }

  commitEditor() {
    if (!this.editorInputs().every((input) => input.reportValidity())) return false

    const values = {
      name: this.itemNameTarget.value.trim(),
      quantity: Number(this.quantityTarget.value),
      unitPrice: Math.round(Number(this.unitPriceTarget.value) * 100),
      vat: Number(this.vatTarget.value)
    }
    if (!values.name) {
      this.itemNameTarget.setCustomValidity("Le titre est requis.")
      this.itemNameTarget.reportValidity()
      this.itemNameTarget.setCustomValidity("")
      return false
    }

    const row = this.editingRow || this.createRow(this.nextIndex++)
    Object.assign(row.dataset, { name: values.name, quantity: values.quantity, unitPrice: values.unitPrice, vat: values.vat })
    this.setHidden(row.dataset.index, "name", values.name)
    this.setHidden(row.dataset.index, "quantity", values.quantity)
    this.setHidden(row.dataset.index, "unit_price", values.unitPrice)
    this.setHidden(row.dataset.index, "vat", values.vat)
    this.renderRow(row)
    row.classList.remove("hidden")
    row.classList.add("table-row")
    this.hideEditor()
    this.editingRow = null
    this.toggleActions(false)
    this.dirty = true
    this.updateTotals()
    return true
  }

  remove(event) {
    const row = event.currentTarget.closest('[data-quote-editor-target~="row"]')
    const idInput = this.hidden(row.dataset.index, "id")
    if (idInput) {
      this.setHidden(row.dataset.index, "destroy", "1")
      row.classList.add("hidden", "removed")
      row.classList.remove("table-row")
    } else {
      this.element.querySelectorAll(`[name^="quote[quote_items_attributes][${row.dataset.index}]"]`).forEach((input) => input.remove())
      row.remove()
    }
    this.dirty = true
    this.updateTotals()
    if (this.activeRows().length === 0) this.add()
  }

  submit(event) {
    if (!this.editorTarget.classList.contains("hidden") && !this.commitEditor()) {
      event.preventDefault()
      return
    }
    this.dirty = false
  }

  toggleActions(disabled) {
    this.editButtonTargets.forEach((button) => button.disabled = disabled)
    this.deleteButtonTargets.forEach((button) => button.disabled = disabled)
    this.addButtonTarget.disabled = disabled
  }

  activeRows() {
    return this.rowTargets.filter((row) => !row.classList.contains("removed"))
  }

  prepareEmptyEditor() {
    this.editingRow = null
    this.toggleEditorInputs(false)
    this.itemNameTarget.value = ""
    this.quantityTarget.value = 1
    this.unitPriceTarget.value = ""
    this.vatTarget.value = "20"
    this.toggleActions(true)
    this.updatePreview()
  }

  hideEditor() {
    this.editorTarget.classList.add("hidden")
    this.editorTarget.classList.remove("table-row")
    this.itemNameTarget.value = ""
    this.quantityTarget.value = ""
    this.unitPriceTarget.value = ""
    this.vatTarget.selectedIndex = 0
    this.previewVatTarget.textContent = "—"
    this.previewTtcTarget.textContent = "—"
    this.toggleEditorInputs(true)
  }

  toggleEditorInputs(disabled) {
    this.editorInputs().forEach((input) => input.disabled = disabled)
  }

  editorInputs() {
    return [this.itemNameTarget, this.quantityTarget, this.unitPriceTarget, this.vatTarget]
  }

  updatePreview() {
    const quantity = Number(this.quantityTarget.value) || 0
    const cents = Math.round((Number(this.unitPriceTarget.value) || 0) * 100)
    const vat = Number(this.vatTarget.value) || 0
    const totalVat = Math.floor(cents * vat / 100) * quantity
    this.previewVatTarget.textContent = this.money(totalVat)
    this.previewTtcTarget.textContent = this.money(cents * quantity + totalVat)
  }

  updateTotals() {
    let ht = 0
    let vat = 0
    this.rowTargets.filter((row) => !row.classList.contains("removed")).forEach((row) => {
      const lineHt = Number(row.dataset.unitPrice) * Number(row.dataset.quantity)
      ht += lineHt
      vat += Math.floor(Number(row.dataset.unitPrice) * Number(row.dataset.vat) / 100) * Number(row.dataset.quantity)
    })
    this.totalHtTarget.textContent = this.money(ht)
    this.totalVatTarget.textContent = this.money(vat)
    this.totalTtcTarget.textContent = this.money(ht + vat)
  }

  renderRow(row) {
    const cents = Number(row.dataset.unitPrice)
    const quantity = Number(row.dataset.quantity)
    const vat = Number(row.dataset.vat)
    row.querySelector('[data-field="name"]').textContent = row.dataset.name
    row.querySelector('[data-field="quantity"]').textContent = quantity
    row.querySelector('[data-field="unit-price"]').textContent = this.money(cents)
    row.querySelector('[data-field="vat"]').textContent = `${String(vat).replace(".", ",")} %`
    const totalVat = Math.floor(cents * vat / 100) * quantity
    row.querySelector('[data-field="total-vat"]').textContent = this.money(totalVat)
    row.querySelector('[data-field="total-ttc"]').textContent = this.money(cents * quantity + totalVat)
  }

  createRow(index) {
    const row = this.rowTemplateTarget.content.firstElementChild.cloneNode(true)
    row.dataset.index = index
    this.editorTarget.before(row)
      ;["name", "quantity", "unit_price", "vat", "destroy"].forEach((attribute) => {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = `quote[quote_items_attributes][${index}][${attribute === "destroy" ? "_destroy" : attribute}]`
        input.dataset.attribute = attribute
        input.value = attribute === "destroy" ? "0" : ""
        this.element.append(input)
      })
    return row
  }

  hidden(index, attribute) {
    return this.element.querySelector(`[name="quote[quote_items_attributes][${index}][${attribute === "destroy" ? "_destroy" : attribute}]"]`)
  }

  setHidden(index, attribute, value) { this.hidden(index, attribute).value = value }
  money(cents) { return new Intl.NumberFormat("fr-FR", { style: "currency", currency: "EUR" }).format(cents / 100) }
}
