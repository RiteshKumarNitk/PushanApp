
// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        // Create a Supabase client with the Auth context of the user that called the function.
        // This will likely be the Admin user from the Flutter app.
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
            { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
        )

        // Check if the user making the request is an Admin
        const {
            data: { user },
        } = await supabaseClient.auth.getUser()

        if (!user) {
            throw new Error("Unauthorized");
        }

        // Verify role 'admin' in profiles/users table
        // Assuming 'users' table has the role.
        const { data: userProfile, error: profileError } = await supabaseClient
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single();

        if (profileError || userProfile?.role !== 'admin') {
            return new Response(
                JSON.stringify({ error: 'Unauthorized: Admin access required' }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
            )
        }

        // Now use the SERVICE ROLE key to create the new user
        // This bypasses RLS and allows creating users with specific roles
        const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const { email, password, fullName, phone, addressLine, city, state, zipCode } = await req.json()

        if (!email || !password) {
            throw new Error("Email and Password are required");
        }

        // 1. Create User in Auth
        const { data: userData, error: createError } = await supabaseAdmin.auth.admin.createUser({
            email: email,
            password: password,
            email_confirm: true, // Auto confirm
            user_metadata: { full_name: fullName }
        })

        if (createError) throw createError;
        if (!userData.user) throw new Error("Failed to create user");

        // 2. Add to public.users table (or whatever your profile table is)
        // The trigger might handle this, but let's be explicit if we need to set role 'vip'
        // If you have a trigger that auto-creates profiles on signup, we might need to UPDATE it instead.
        // Let's assume we need to upsert or update.

        // Check if profile exists (from trigger)
        const { data: existingProfile } = await supabaseAdmin
            .from('users')
            .select('id')
            .eq('id', userData.user.id)
            .single();

        let profileError2;
        if (existingProfile) {
            const { error } = await supabaseAdmin
                .from('users')
                .update({
                    role: 'vip',
                    full_name: fullName,
                    phone: phone, // Optional
                })
                .eq('id', userData.user.id);
            profileError2 = error;
        } else {
            const { error } = await supabaseAdmin
                .from('users')
                .insert({
                    id: userData.user.id,
                    email: email, // If you store email in public table
                    role: 'vip',
                    full_name: fullName,
                    phone: phone,
                });
            profileError2 = error;
        }

        if (profileError2) throw profileError2;

        // 3. Insert Address if provided
        // variables addressLine, city, state, zipCode are already extracted from req.json() above
        if (addressLine && city && state) {
            const { error: addrError } = await supabaseAdmin
                .from('user_addresses')
                .insert({
                    user_id: userData.user.id,
                    label: 'Home', // Default label
                    address_line: addressLine,
                    city: city,
                    state: state,
                    zip_code: zipCode,
                    is_default: true
                });
            if (addrError) console.error("Address Insert Error:", addrError);
        }

        return new Response(
            JSON.stringify(userData),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
    }
})
