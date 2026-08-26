// Crée un paiement Konnect pour l'éleveur connecté (passage au plan
// premium) et renvoie l'URL de paiement à ouvrir dans le navigateur.
//
// Secrets requis (à définir via `supabase secrets set`) :
//   KONNECT_API_KEY      — clé API de votre compte marchand Konnect
//   KONNECT_WALLET_ID    — id du portefeuille (receiverWalletId) Konnect
//   KONNECT_WEBHOOK_URL  — URL publique de la fonction konnect-webhook
//   PREMIUM_PRICE_MILLIMES — prix de l'abonnement premium, en millimes
//                            (ex: 15000 = 15.000 DT)

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Non authentifié" }), { status: 401 });
  }

  // Client Supabase authentifié comme l'appelant, pour retrouver son profil.
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

  const montant = Number(Deno.env.get("PREMIUM_PRICE_MILLIMES") ?? "15000");

  const konnectRes = await fetch("https://api.konnect.network/api/v2/payments/init-payment", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": Deno.env.get("KONNECT_API_KEY")!,
    },
    body: JSON.stringify({
      receiverWalletId: Deno.env.get("KONNECT_WALLET_ID"),
      token: "TND",
      amount: montant,
      type: "immediate",
      description: "Nidus — Abonnement Premium",
      acceptedPaymentMethods: ["wallet", "bank_card", "e-DINAR"],
      lifespan: 30,
      checkoutForm: true,
      addPaymentFeesToAmount: true,
      email: eleveur.email,
      orderId: eleveur.id, // sert à retrouver l'éleveur dans le webhook
      webhook: Deno.env.get("KONNECT_WEBHOOK_URL"),
      silentWebhook: true,
    }),
  });

  if (!konnectRes.ok) {
    const detail = await konnectRes.text();
    return new Response(JSON.stringify({ error: "Échec de création du paiement", detail }), {
      status: 502,
    });
  }

  const { payUrl, paymentRef } = await konnectRes.json();

  return new Response(JSON.stringify({ payUrl, paymentRef }), {
    headers: { "content-type": "application/json" },
  });
});
