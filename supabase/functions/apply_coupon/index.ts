
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { couponCode, totalAmount } = await req.json()

    // In a real app, you would query a 'coupons' table
    // For this demo, we hardcode the logic as requested
    // "20 percent off offers"

    // Check for specific broadcasting coupons
    // Ideally this matches the "title" or a secret code from the announcement
    // Let's assume a standard code for now or check DB

    // Hardcoded logic for MVP:
    if (couponCode.toUpperCase() === 'TEA20' || couponCode.toUpperCase() === 'WELCOME20') {
      const discount = totalAmount * 0.20
      return new Response(
        JSON.stringify({
          valid: true,
          discount: discount,
          message: 'Coupon applied successfully! You saved 20%'
        }),
        { headers: { "Content-Type": "application/json" } },
      )
    }

    return new Response(
      JSON.stringify({ valid: false, message: 'Invalid or expired coupon code.' }),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    })
  }
})
