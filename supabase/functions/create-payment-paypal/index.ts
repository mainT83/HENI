// Crée une commande PayPal pour passer l'éleveur connecté en premium
// (clients internationaux — les clients tunisiens utilisent Konnect, voir
// create-payment/index.ts). Renvoie le lien d'approbation PayPal à ouvrir
// dans le navigateur.
//
// Secrets requis :
//   PAYPAL_CLIENT_ID
//   PAYPAL_CLIENT_SECRET
//   PAYPAL_API_BASE       — https://api-m.paypal.com (live) ou
//                            https://api-m.sandbox.paypal.com (tests)
//   PREMIUM_PRICE_USD     — ex: 5.00

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

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Non authentifié" }), { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: "Non authentifié" }), { status: 401 });
  }
  const eleveur = userData.user;

  const base = Deno.env.get("PAYPAL_API_BASE") ?? "https://api-m.paypal.com";
  const jeton = await obtenirJetonAcces(
    base,
    Deno.env.get("PAYPAL_CLIENT_ID")!,
    Deno.env.get("PAYPAL_CLIENT_SECRET")!,
  );

  const prix = Deno.env.get("PREMIUM_PRICE_USD") ?? "5.00";
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;

  const commandeRes = await fetch(`${base}/v2/checkout/orders`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      Authorization: `Bearer ${jeton}`,
    },
    body: JSON.stringify({
      intent: "CAPTURE",
      purchase_units: [
        {
          custom_id: eleveur.id, // sert à retrouver l'éleveur après capture
          description: "Nidus — Abonnement Premium",
          amount: { currency_code: "USD", value: prix },
        },
      ],
      application_context: {
        brand_name: "Nidus",
        user_action: "PAY_NOW",
        return_url: `${supabaseUrl}/functions/v1/paypal-return`,
        cancel_url: `${supabaseUrl}/functions/v1/paypal-return?annule=1`,
      },
    }),
  });

  if (!commandeRes.ok) {
    const detail = await commandeRes.text();
    return new Response(JSON.stringify({ error: "Échec de création de la commande PayPal", detail }), {
      status: 502,
    });
  }

  const commande = await commandeRes.json();
  const lienApprobation = commande.links?.find((l: { rel: string }) => l.rel === "approve")?.href;

  if (!lienApprobation) {
    return new Response(JSON.stringify({ error: "Lien d'approbation PayPal introuvable" }), {
      status: 502,
    });
  }

  return new Response(JSON.stringify({ payUrl: lienApprobation }), {
    headers: { "content-type": "application/json" },
  });
});
