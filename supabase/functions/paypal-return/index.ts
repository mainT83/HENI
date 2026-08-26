// Reçoit le retour du navigateur après approbation PayPal (?token=ORDER_ID),
// capture le paiement côté serveur, puis passe l'éleveur en premium.
// À déployer avec --no-verify-jwt (appelé par le navigateur du client, sans
// jeton Supabase).

import { createClient } from "jsr:@supabase/supabase-js@2";

async function obtenirJetonAcces(base: string, clientId: string, secret: string) {
  const res = await fetch(`${base}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${clientId}:${secret}`)}`,
      "content-type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!res.ok) throw new Error("Échec d'authentification PayPal");
  const data = await res.json();
  return data.access_token as string;
}

function pageHtml(titre: string, message: string) {
  return `<!doctype html><html><head><meta charset="utf-8"><title>${titre}</title>
<style>body{font-family:system-ui,sans-serif;background:#f6f3ec;color:#2e3625;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;text-align:center;padding:24px}
.box{max-width:420px}h1{font-size:22px}p{color:#6b7259}</style></head>
<body><div class="box"><h1>${titre}</h1><p>${message}</p></div></body></html>`;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);

  if (url.searchParams.get("annule") === "1") {
    return new Response(pageHtml("Paiement annulé", "Vous pouvez revenir dans l'application pour réessayer."), {
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }

  const orderId = url.searchParams.get("token");
  if (!orderId) {
    return new Response(pageHtml("Erreur", "Référence de commande manquante."), {
      status: 400,
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }

  const base = Deno.env.get("PAYPAL_API_BASE") ?? "https://api-m.paypal.com";
  const jeton = await obtenirJetonAcces(
    base,
    Deno.env.get("PAYPAL_CLIENT_ID")!,
    Deno.env.get("PAYPAL_CLIENT_SECRET")!,
  );

  const captureRes = await fetch(`${base}/v2/checkout/orders/${orderId}/capture`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      Authorization: `Bearer ${jeton}`,
    },
  });

  if (!captureRes.ok) {
    const detail = await captureRes.text();
    console.error("Échec de capture PayPal:", detail);
    return new Response(pageHtml("Paiement non confirmé", "Contactez-nous si le montant a été débité."), {
      status: 502,
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }

  const capture = await captureRes.json();
  const statutOk = capture.status === "COMPLETED";
  const eleveurId = capture.purchase_units?.[0]?.payments?.captures?.[0]?.custom_id
    ?? capture.purchase_units?.[0]?.custom_id;

  if (!statutOk || !eleveurId) {
    return new Response(pageHtml("Paiement non confirmé", "Contactez-nous si le montant a été débité."), {
      status: 200,
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await supabaseAdmin.from("profiles").update({ is_premium: true }).eq("id", eleveurId);

  if (error) {
    console.error("Erreur mise à jour profil:", error.message);
    return new Response(pageHtml("Paiement reçu", "Une erreur technique est survenue, contactez-nous pour débloquer votre compte."), {
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }

  return new Response(
    pageHtml("Paiement confirmé ✓", "Votre compte Nidus est maintenant premium. Retournez dans l'application."),
    { headers: { "content-type": "text/html; charset=utf-8" } },
  );
});
