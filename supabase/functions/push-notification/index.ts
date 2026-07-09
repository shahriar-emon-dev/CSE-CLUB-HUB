import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')

serve(async (req) => {
  try {
    const payload = await req.json()
    const { notification_id, user_id, title, body, type, entity_type, entity_id } = payload

    if (!user_id || !title || !body) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 })
    }

    // Initialize Supabase Client to fetch FCM tokens
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Fetch the target user's FCM tokens
    const { data: tokens, error } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', user_id)

    if (error) throw error

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No devices registered for user' }), { status: 200 })
    }

    const deviceTokens = tokens.map((t) => t.token)

    // Construct Firebase payload
    // We send data-only messages if we want Flutter to handle background rendering,
    // or notification messages if we want OS to render it automatically.
    // We'll use both for maximum compatibility, but put rich data in the `data` payload.
    const fcmPayload = {
      registration_ids: deviceTokens,
      notification: {
        title,
        body,
        sound: 'default',
        badge: '1'
      },
      data: {
        type: type || 'general',
        entity_type: entity_type || '',
        entity_id: entity_id || '',
        notification_id: notification_id || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    }

    // Send to FCM
    const fcmRes = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${fcmServerKey}`
      },
      body: JSON.stringify(fcmPayload)
    })

    const fcmData = await fcmRes.json()

    // Handle invalid tokens (clean up)
    if (fcmData.results) {
      const tokensToDelete: string[] = []
      fcmData.results.forEach((result: any, index: number) => {
        if (result.error === 'NotRegistered' || result.error === 'InvalidRegistration') {
          tokensToDelete.push(deviceTokens[index])
        }
      })

      if (tokensToDelete.length > 0) {
        await supabase
          .from('fcm_tokens')
          .delete()
          .in('token', tokensToDelete)
      }
    }

    return new Response(JSON.stringify({ success: true, fcmResponse: fcmData }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
