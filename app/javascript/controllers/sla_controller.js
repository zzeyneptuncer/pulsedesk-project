import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { due: String, solved: Boolean }

  connect() {
    if (this.solvedValue) return
    this.refresh()
    this.timer = setInterval(() => this.refresh(), 1000)
  }

  disconnect() { clearInterval(this.timer) }

  refresh() {
    const remaining = (Date.parse(this.dueValue) - Date.now()) / 1000
    const breached = remaining < 0
    const seconds = Math.floor(Math.abs(remaining))
    const duration = `${Math.floor(seconds / 3600)} sa ${Math.floor(seconds % 3600 / 60)} dk`
    this.element.textContent = breached ? `SLA AŞILDI · ${duration}` : `${duration} kaldı`
    this.element.classList.toggle("breached", breached)
    this.element.classList.toggle("healthy", !breached)
  }
}
