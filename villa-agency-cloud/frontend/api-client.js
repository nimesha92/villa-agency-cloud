(function () {
  const listEl = document.getElementById("dynamic-properties-list");
  if (listEl) {
    fetch("/properties")
      .then(r => r.json())
      .then(items => {
        if (!Array.isArray(items) || items.length === 0) return;
        listEl.innerHTML = items.map(p => `
          <div class="col-lg-4 col-md-6 align-self-center mb-30 properties-items">
            <div class="item">
              <span class="category">${p.property_type} (${p.property_status})</span>
              <h6>$${Number(p.price).toLocaleString()}</h6>
              <h4><a href="property-details.html?id=${p.property_id}">${p.property_title}</a></h4>
              <ul>
                <li>Bedrooms: <span>${p.bedrooms}</span></li>
                <li>Bathrooms: <span>${p.bathrooms}</span></li>
                <li>Area: <span>${p.floor_area}m2</span></li>
                <li>Agent: <span>${p.assigned_agent}</span></li>
              </ul>
              <div class="main-button">
                <a href="contact.html?property_id=${p.property_id}">Schedule a visit</a>
              </div>
            </div>
          </div>
        `).join("");
      })
      .catch(err => console.warn("Properties fetch error:", err));
  }

  const form = document.getElementById("contact-form") || document.querySelector("form");
  if (form) {
    form.addEventListener("submit", async function (e) {
      e.preventDefault();
      const params = new URLSearchParams(window.location.search);
      const getVal = (selectors, fallback) => {
        for (const s of selectors) {
          const el = form.querySelector(s);
          if (el && el.value.trim()) return el.value.trim();
        }
        return fallback;
      };

      const payload = {
        property_id: parseInt(params.get("property_id") || "1", 10),
        customer_name: getVal(["#name", "[name='name']", "input[type='text']"], "Website Visitor"),
        customer_email: getVal(["#email", "[name='email']", "input[type='email']"], "visitor@villa.lk"),
        contact_number: getVal(["#phone", "[name='phone']", "#subject", "[name='subject']"], "0710000000"),
        preferred_viewing_datetime: new Date(Date.now() + 86400000).toISOString(),
        enquiry_message: getVal(["#message", "[name='message']", "textarea"], "Viewing request"),
        enquiry_status: "Pending"
      };

      try {
        const res = await fetch("/enquiries", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (res.ok) {
          alert(`Viewing enquiry saved! Total enquiries for Property #${payload.property_id}: ${data.total_enquiries_for_property}` +
                (data.serverless_triggered ? " - Threshold exceeded: Serverless alert triggered!" : ""));
          form.reset();
        } else {
          alert("Error saving enquiry: " + JSON.stringify(data));
        }
      } catch (err) {
        alert("Network error: " + err.message);
      }
    });
  }
})();

