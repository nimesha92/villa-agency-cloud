(function() {
  const ANALYTICS_API = "/track";
  const sessionId = sessionStorage.getItem("villa_sess") || ("sess_" + Math.random().toString(36).substring(2, 10));
  sessionStorage.setItem("villa_sess", sessionId);

  function sendMetric(eventType, category, value) {
    fetch(ANALYTICS_API, {
      method: "POST",
      keepalive: true,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        event_type: eventType,
        property_category: category,
        page_url: window.location.pathname,
        session_id: sessionId,
        engagement_value: value
      })
    }).then(response => {
      if (!response.ok) {
        throw new Error(`POST ${ANALYTICS_API} returned HTTP ${response.status}`);
      }
    }).catch(err => console.warn("Analytics error:", err));
  }

  // Metric 1: Page Impression across any page
  window.addEventListener("load", () => {
    sendMetric("page_impression", document.title || "Villa Page", window.location.pathname);
  });

  // Metric 2 & 3: Category Filter Clicks & High-Intent Lead Actions
  document.addEventListener("click", (e) => {
    const el = e.target.closest("a, button");
    if (!el) return;
    const text = (el.innerText || "").trim();

    if (el.matches("a[data-filter], button[data-bs-toggle='tab']")) {
      sendMetric("category_filter_click", text, "Filter Selected");
    } else if (text.toLowerCase().includes("schedule a visit") || text.toLowerCase().includes("send message")) {
      sendMetric("schedule_visit_click", "High Intent Lead", text);
    }
  });

  // Metric 4: Scroll Engagement (50% Read Depth)
  let scrolled50 = false;
  window.addEventListener("scroll", () => {
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    if (docHeight > 0 && (window.scrollY / docHeight) >= 0.5 && !scrolled50) {
      scrolled50 = true;
      sendMetric("scroll_depth_50", "Engagement", "50% Page Scrolled");
    }
  });
})();
