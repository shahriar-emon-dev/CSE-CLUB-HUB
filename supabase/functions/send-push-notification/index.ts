import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// To send FCM notifications, we need a Google OAuth2 token.
// The easiest way in a Deno edge function is to use googleapis or a simpler JWT approach.
// Using google-auth-library:
import { JWT } from 'npm:google-auth-library'

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
    const { title, body, userIds, data } = await req.json()

    if (!title || !body || !userIds || !Array.isArray(userIds)) {
      throw new Error('Invalid request payload. Must provide title, body, and array of userIds.')
    }

    // 1. Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Supabase configuration is missing.')
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 2. Fetch FCM tokens for the given users
    const { data: profiles, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token')
      .in('id', userIds)
      .not('fcm_token', 'is', null)

    if (profileError) {
      throw profileError
    }

    const tokens = profiles.map((p) => p.fcm_token).filter(Boolean)

    if (tokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No valid FCM tokens found for users.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // 3. Authenticate with Firebase using Service Account JSON
    // You MUST store your Firebase Service Account JSON string in the Supabase Secret `FIREBASE_SERVICE_ACCOUNT`
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT secret is missing.')
    }

    const serviceAccount = JSON.parse(serviceAccountJson)

    // Generate OAuth2 token
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    const tokenResponse = await jwtClient.getAccessToken()
    const accessToken = tokenResponse.token

    if (!accessToken) {
      throw new Error('Failed to get FCM access token')
    }

    // 4. Send notification via FCM v1 API (we loop or use multicast if supported, but v1 supports messages individually)
    // For simplicity, we send them individually in parallel. In production, consider batching if many tokens.
    
    const projectId = serviceAccount.project_id
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    const sendPromises = tokens.map(async (token) => {
      const payload = {
        message: {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: data || {},
        }
      }

      const response = await fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      })

      return response.json()
    })

    const results = await Promise.all(sendPromises)

    return new Response(JSON.stringify({ message: 'Notifications processed', results }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
