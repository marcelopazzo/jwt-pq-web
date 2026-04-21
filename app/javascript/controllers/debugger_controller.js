import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["token", "pubkey", "header", "payload", "signature"]
  static values  = { verifyUrl: String, samplesUrl: String }

  async verify() {
    this.setStatus("Verifying...", "busy")
    try {
      const res = await fetch(this.verifyUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({
          token: this.tokenTarget.value,
          pubkey: this.pubkeyTarget.value
        })
      })
      const data = await res.json()
      this.render(data)
    } catch (e) {
      this.setStatus(`Network error: ${e.message}`, "error")
    }
  }

  async loadSample(event) {
    const alg = event.currentTarget.dataset.sample
    try {
      const res = await fetch(`${this.samplesUrlValue}/${alg}`)
      const data = await res.json()
      this.tokenTarget.value  = data.token
      this.pubkeyTarget.value = JSON.stringify(data.jwk, null, 2)
      this.setStatus("Sample loaded. Click Verify.", "idle")
    } catch (e) {
      this.setStatus(`Could not load sample: ${e.message}`, "error")
    }
  }

  render(data) {
    if (data.valid) {
      this.headerTarget.textContent  = JSON.stringify(data.header,  null, 2)
      this.payloadTarget.textContent = JSON.stringify(data.payload, null, 2)
      this.setStatus(`Signature valid — ${data.algorithm}`, "ok")
    } else {
      this.headerTarget.textContent  = "—"
      this.payloadTarget.textContent = "—"
      this.setStatus(
        `Invalid: ${data.error}${data.detail ? ` (${data.detail})` : ""}`,
        "fail"
      )
    }
  }

  setStatus(msg, kind) {
    this.signatureTarget.textContent = msg
    this.signatureTarget.className   = `status status--${kind} p-3 rounded border text-sm`
  }

  csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }
}
