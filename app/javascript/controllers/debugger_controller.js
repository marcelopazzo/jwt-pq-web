import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "token", "pubkey",
    "header", "payload",
    "status", "statusMessage", "statusMeta",
    "tokenCount", "pubkeyCount",
    "algChip", "submit"
  ]
  static values = { verifyUrl: String, samplesUrl: String }

  connect() {
    this.updateCounts()
  }

  async verify() {
    this.#setBusy("Verifying against jwt-pq...")
    const t0 = performance.now()

    try {
      const res = await fetch(this.verifyUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.#csrfToken()
        },
        body: JSON.stringify({
          token: this.tokenTarget.value,
          pubkey: this.pubkeyTarget.value
        })
      })
      const data = await res.json()
      this.#render(data, performance.now() - t0)
    } catch (e) {
      this.#setState("error", `Network error: ${e.message}`, "")
      this.#resetOutputs()
    } finally {
      this.#setBusyFlag(false)
    }
  }

  async loadSample(event) {
    const alg = event.currentTarget.dataset.sample
    this.#setBusy(`Fetching ${alg.replace("_", "-").toUpperCase()} sample...`)
    try {
      const res = await fetch(`${this.samplesUrlValue}/${alg}`)
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = await res.json()
      this.tokenTarget.value  = data.token
      this.pubkeyTarget.value = JSON.stringify(data.jwk, null, 2)
      this.updateCounts()
      this.#setState("idle", `Sample loaded — ${data.algorithm}. Click Verify.`, "")
      this.#resetOutputs()
    } catch (e) {
      this.#setState("error", `Could not load sample: ${e.message}`, "")
    } finally {
      this.#setBusyFlag(false)
    }
  }

  clear() {
    this.tokenTarget.value  = ""
    this.pubkeyTarget.value = ""
    this.updateCounts()
    this.#resetOutputs()
    this.#setState("idle", "Cleared. Paste a token, or load a sample.", "")
  }

  updateCounts() {
    if (this.hasTokenCountTarget) {
      const n = new Blob([this.tokenTarget.value]).size
      this.tokenCountTarget.textContent = `${n.toLocaleString()} bytes`
    }
    if (this.hasPubkeyCountTarget) {
      const n = new Blob([this.pubkeyTarget.value]).size
      this.pubkeyCountTarget.textContent = `${n.toLocaleString()} bytes`
    }
  }

  #render(data, elapsedMs) {
    const meta = `${elapsedMs.toFixed(0)}ms`
    if (data.valid) {
      this.headerTarget.textContent  = JSON.stringify(data.header,  null, 2)
      this.payloadTarget.textContent = JSON.stringify(data.payload, null, 2)
      this.#showAlgChip(data.algorithm)
      this.#setState("ok", `Signature valid — ${data.algorithm}`, meta)
    } else {
      this.#resetOutputs()
      const detail = data.detail ? ` (${data.detail})` : ""
      this.#setState("fail", `Invalid — ${data.error}${detail}`, meta)
    }
  }

  #resetOutputs() {
    this.headerTarget.textContent  = "{\n  /* header will appear here after verify */\n}"
    this.payloadTarget.textContent = "{\n  /* payload claims will appear here */\n}"
    this.#hideAlgChip()
  }

  #showAlgChip(alg) {
    if (!this.hasAlgChipTarget) return
    this.algChipTarget.textContent = alg
    this.algChipTarget.hidden = false
  }

  #hideAlgChip() {
    if (!this.hasAlgChipTarget) return
    this.algChipTarget.textContent = ""
    this.algChipTarget.hidden = true
  }

  #setBusy(message) {
    this.#setState("busy", message, "")
    this.#setBusyFlag(true)
  }

  #setBusyFlag(busy) {
    if (!this.hasSubmitTarget) return
    this.submitTarget.disabled = busy
    this.submitTarget.setAttribute("aria-busy", busy ? "true" : "false")
  }

  #setState(state, message, meta) {
    if (this.hasStatusTarget) {
      this.statusTarget.dataset.state = state
    }
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.textContent = message
    }
    if (this.hasStatusMetaTarget) {
      this.statusMetaTarget.textContent = meta || ""
    }
  }

  #csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }
}
