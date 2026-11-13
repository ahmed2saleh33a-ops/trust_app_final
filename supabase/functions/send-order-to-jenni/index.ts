// supabase/functions/send-order-to-jenni/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// ============== تكوين Supabase ==============
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// ============== نظام الزعيم (Jenni) API عبر الوكيل ==============
// ✅ تم تغيير الرابط ليوجه الطلبات عبر خادم Hetzner الخاص بك
const JENNI_BASE_URL = "http://89.167.95.118:8080/jenni/api";
const PROXY_SECRET = "eb8ebd362405ede0b02ec342ca8b1c9c1ca5fe20df4ac5e314b8523196ee2fbd";

let jenniToken: string | null = null;
let tokenExpiry: Date | null = null;

// ============== خريطة تحويل أسماء المحافظات إلى أكواد (مصححة بالكامل) ==============
const governorateMap: { [key: string]: string } = {
  'بغداد': 'BGD',
  'البصرة': 'BAS',
  'نينوى': 'NIN',
  'أربيل': 'ARB',
  'النجف': 'NJF',
  'كركوك': 'KRK',
  'الأنبار': 'ANB',
  'كربلاء': 'KRB',
  'ذي قار': 'DHI',
  'ميسان': 'MYS',
  'بابل': 'BBL',
  'واسط': 'WST',
  'صلاح الدين': 'SAH',
  'ديالى': 'DYL',
  'المثنى': 'MTH',
  'القادسية': 'QAD',
  'السليمانية': 'SMH',
  'دهوك': 'DOH',
};

function getGovernorateCode(name: string): string {
  if (!name) return 'BGD';
  if (name.length <= 3 && /^[A-Z]{3}$/.test(name)) {
    return name;
  }
  const code = governorateMap[name];
  if (code) return code;
  for (const [key, value] of Object.entries(governorateMap)) {
    if (name.includes(key) || key.includes(name)) {
      return value;
    }
  }
  console.log(`⚠️ محافظة غير معروفة: "${name}"، استخدام BGD كافتراضي`);
  return 'BGD';
}

// ============== رؤوس CORS ==============
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Accept, Authorization, X-API-Key",
  "Access-Control-Max-Age": "86400",
};

// ============== مصادقة نظام الزعيم ==============
async function loginToJenni(): Promise<{ success: boolean; token?: string; data?: any }> {
  try {
    const username = Deno.env.get("JENNI_USERNAME");
    const password = Deno.env.get("JENNI_PASSWORD");
    
    console.log(`🔍 JENNI_USERNAME: ${username ? '✅ موجود' : '❌ غير موجود'}`);
    console.log(`🔍 JENNI_PASSWORD: ${password ? '✅ موجود' : '❌ غير موجود'}`);
    
    if (!username || !password) {
      console.error("❌ JENNI_USERNAME أو JENNI_PASSWORD غير موجودين في المتغيرات البيئية");
      return { success: false };
    }
    
    console.log("🔐 محاولة تسجيل الدخول إلى نظام الزعيم عبر الوكيل...");
    console.log(`📝 باستخدام username: ${username}`);
    
    // ✅ إضافة X-Proxy-Secret
    const response = await fetch(`${JENNI_BASE_URL}/v2/auth/login`, {
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
        "X-Proxy-Secret": PROXY_SECRET,
      },
      body: JSON.stringify({ username, password }),
    });
    
    if (response.ok) {
      const data = await response.json();
      console.log("✅ تم تسجيل الدخول إلى نظام الزعيم بنجاح");
      console.log(`📝 بيانات الرد: ${JSON.stringify(data).substring(0, 200)}`);
      
      let token = data.token || data.access_token || data.api_key || null;
      
      if (token) {
        jenniToken = token.replace(/^Bearer\s+/, '');
        const expiresIn = data.expires_in || 86400;
        tokenExpiry = new Date(Date.now() + expiresIn * 1000);
        console.log(`📝 التوكن النقي: ${jenniToken.substring(0, 20)}... (تم الحصول عليه)`);
        return { success: true, token: jenniToken, data: data };
      } else {
        console.error("❌ لا يوجد توكن في رد تسجيل الدخول");
        return { success: false, data: data };
      }
    } else {
      const errorText = await response.text();
      console.error("❌ فشل تسجيل الدخول إلى نظام الزعيم:", response.status);
      console.error("❌ تفاصيل الخطأ:", errorText);
      return { success: false };
    }
  } catch (error) {
    console.error("❌ خطأ في تسجيل الدخول:", error);
    return { success: false };
  }
}

async function getValidToken(): Promise<string | null> {
  if (jenniToken && tokenExpiry && new Date() < tokenExpiry) {
    console.log("✅ استخدام توكن موجود وصالح");
    return jenniToken;
  }
  
  console.log("🔄 التوكن منتهي أو غير موجود، محاولة تسجيل الدخول...");
  const result = await loginToJenni();
  return result.success ? result.token || null : null;
}

// ============== إرسال الطلب إلى نظام الزعيم ==============
async function sendOrderToJenni(orderData: any, uniqueId: string): Promise<any> {
  try {
    let token = await getValidToken();
    
    if (!token) {
      console.log("🔄 لا يوجد توكن، محاولة تسجيل الدخول...");
      const loginResult = await loginToJenni();
      if (!loginResult.success || !loginResult.token) {
        throw new Error("فشل تسجيل الدخول إلى نظام الزعيم");
      }
      token = loginResult.token;
    }
    
    if (!token) {
      throw new Error("لا يوجد توكن صالح لنظام الزعيم");
    }
    
    const governorateCode = getGovernorateCode(orderData.governorate || "بغداد");
    console.log(`📍 المحافظة: ${orderData.governorate || "بغداد"} → ${governorateCode}`);
    
    console.log("📤 إرسال الطلب إلى نظام الزعيم عبر الوكيل...");
    console.log(`📦 المنتج: ${orderData.product}`);
    console.log(`💰 السعر: ${orderData.price}`);
    console.log(`🔢 الكمية: ${orderData.quantity}`);
    console.log(`📦 system_code: ${Deno.env.get("JENNI_SYSTEM_CODE") || "TRUST_CENTER_01"}`);
    console.log(`🆔 shipment_number: ${uniqueId}`);
    
    // ✅ إضافة X-Proxy-Secret
    const response = await fetch(`${JENNI_BASE_URL}/v2/shipments/create`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`,
        "X-Proxy-Secret": PROXY_SECRET,
      },
      body: JSON.stringify({
        system_code: Deno.env.get("JENNI_SYSTEM_CODE") || "TRUST_CENTER_01",
        shipments: [{
          shipment_number: uniqueId,
          external_shipment_id: uniqueId,
          receiver_name: orderData.customer_name || "",
          receiver_phone_1: orderData.customer_phone || "",
          governorate_code: governorateCode,
          city: orderData.district || "",
          address: orderData.customer_address || "",
          amount_iqd: orderData.total || orderData.price || 0,
          quantity: orderData.quantity || 1,
          product_info: orderData.product || "",
          note: orderData.admin_notes || "",
        }]
      }),
    });
    
    if (response.status === 401) {
      console.log("🔄 التوكن غير صالح، محاولة تسجيل الدخول مجدداً...");
      const loginResult = await loginToJenni();
      if (loginResult.success && loginResult.token) {
        console.log("🔄 إعادة محاولة إرسال الطلب بتوكن جديد...");
        
        // ✅ إضافة X-Proxy-Secret
        const retryResponse = await fetch(`${JENNI_BASE_URL}/v2/shipments/create`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${loginResult.token}`,
            "X-Proxy-Secret": PROXY_SECRET,
          },
          body: JSON.stringify({
            system_code: Deno.env.get("JENNI_SYSTEM_CODE") || "TRUST_CENTER_01",
            shipments: [{
              shipment_number: uniqueId,
              external_shipment_id: uniqueId,
              receiver_name: orderData.customer_name || "",
              receiver_phone_1: orderData.customer_phone || "",
              governorate_code: governorateCode,
              city: orderData.district || "",
              address: orderData.customer_address || "",
              amount_iqd: orderData.total || orderData.price || 0,
              quantity: orderData.quantity || 1,
              product_info: orderData.product || "",
              note: orderData.admin_notes || "",
            }]
          }),
        });
        
        if (retryResponse.ok) {
          const result = await retryResponse.json();
          console.log("✅ تم إرسال الطلب إلى نظام الزعيم بنجاح (بعد إعادة المحاولة)");
          
          const acceptedShipments = result.accepted_shipments || [];
          const rejectedShipments = result.rejected_shipments || [];
          
          if (rejectedShipments.length > 0) {
            console.error("⚠️ تم رفض الشحنة بعد إعادة المحاولة:", JSON.stringify(rejectedShipments));
            return { 
              success: false, 
              error: rejectedShipments[0]?.reason || "تم رفض الشحنة" 
            };
          }
          
          const shipmentId = acceptedShipments.length > 0 ? acceptedShipments[0].shipment_id : null;
          return { 
            success: true, 
            data: { 
              shipment_id: shipmentId,
              ...result 
            } 
          };
        } else {
          console.error("❌ فشل إعادة المحاولة:", retryResponse.status);
          const errorText = await retryResponse.text();
          console.error("❌ تفاصيل الخطأ:", errorText);
          return { success: false, error: `HTTP ${retryResponse.status}: ${errorText}` };
        }
      }
    }
    
    if (response.ok) {
      const result = await response.json();
      console.log("✅ تم إرسال الطلب إلى نظام الزعيم بنجاح");
      console.log(`📝 رد الزعيم:`, JSON.stringify(result).substring(0, 300));
      
      const acceptedShipments = result.accepted_shipments || [];
      const rejectedShipments = result.rejected_shipments || [];
      
      // ✅ التحقق من وجود شحنات مرفوضة
      if (rejectedShipments.length > 0) {
        console.error("⚠️ تم رفض بعض الشحنات:", JSON.stringify(rejectedShipments));
        const firstRejection = rejectedShipments[0];
        return { 
          success: false, 
          error: firstRejection?.reason || "تم رفض الشحنة من نظام الزعيم",
          errorCode: firstRejection?.error_code || "UNKNOWN_ERROR",
          rejectionDetails: firstRejection,
        };
      }
      
      const shipmentId = acceptedShipments.length > 0 ? acceptedShipments[0].shipment_id : null;
      console.log(`📦 shipment_id المستخرج: ${shipmentId}`);
      
      return { 
        success: true, 
        data: { 
          shipment_id: shipmentId,
          ...result 
        } 
      };
    }
    
    console.error("❌ فشل إرسال الطلب إلى نظام الزعيم:", response.status);
    const errorText = await response.text();
    console.error("❌ تفاصيل الخطأ:", errorText);
    return { success: false, error: `HTTP ${response.status}: ${errorText}` };
  } catch (error) {
    console.error("❌ خطأ في إرسال الطلب إلى نظام الزعيم:", error);
    return { success: false, error: String(error) };
  }
}

// ============== حذف طلب من نظام الزعيم ==============
async function deleteShipmentFromJenni(shipmentId: string): Promise<any> {
  try {
    if (!shipmentId || shipmentId === 'undefined' || shipmentId === 'null') {
      console.error("❌ shipment_id غير صالح:", shipmentId);
      return { success: false, error: "معرف الشحنة غير صالح" };
    }
    
    const token = await getValidToken();
    if (!token) {
      console.error("❌ لا يوجد توكن صالح لنظام الزعيم");
      return { success: false, error: "لا يوجد توكن صالح" };
    }
    
    console.log(`🗑️ محاولة حذف الطلب ${shipmentId} من نظام الزعيم عبر الوكيل...`);
    
    // ✅ إضافة X-Proxy-Secret
    const response = await fetch(`${JENNI_BASE_URL}/v2/orders/${shipmentId}`, {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`,
        "X-Proxy-Secret": PROXY_SECRET,
      },
    });
    
    if (response.ok) {
      console.log(`✅ تم حذف الطلب ${shipmentId} من نظام الزعيم بنجاح`);
      return { success: true };
    } else if (response.status === 404) {
      console.log(`ℹ️ الطلب ${shipmentId} غير موجود في نظام الزعيم (ربما تم حذفه مسبقاً)`);
      return { success: true, message: "الطلب غير موجود في نظام الزعيم" };
    } else if (response.status === 403) {
      console.error(`❌ لا يمكن حذف الطلب ${shipmentId} (الحذف غير مسموح في هذه المرحلة)`);
      const errorText = await response.text();
      console.error("❌ تفاصيل الخطأ:", errorText);
      return { success: false, error: "لا يمكن حذف الطلب في هذه المرحلة (الحذف غير مسموح)" };
    }
    
    console.error("❌ فشل حذف الطلب من نظام الزعيم:", response.status);
    const errorText = await response.text();
    console.error("❌ تفاصيل الخطأ:", errorText);
    return { success: false, error: `HTTP ${response.status}: ${errorText}` };
  } catch (error) {
    console.error("❌ خطأ في حذف الطلب:", error);
    return { success: false, error: String(error) };
  }
}

// ============== استقبال تحديثات الحالة من نظام الزعيم (Webhook) ==============
async function handleStatusUpdate(updateData: any, authHeader?: string): Promise<any> {
  try {
    console.log("📬 استلام تحديث حالة من نظام الزعيم:", JSON.stringify(updateData).substring(0, 500));
    
    const { system_code, updates } = updateData;
    
    if (system_code !== (Deno.env.get("JENNI_SYSTEM_CODE") || "TRUST_CENTER_01")) {
      console.error("❌ system_code غير صحيح");
      return { success: false, error: "system_code غير صحيح" };
    }
    
    const results = [];
    
for (const update of updates) {
  const { shipment_number, external_shipment_id, external_id, shipment_id, action_code, current_step, current_step_ar, note } = update;      
      console.log(`📦 تحديث للشحنة: ${shipment_number} (ID: ${shipment_id})`);
      console.log(`📊 الحالة الجديدة: ${current_step} (${current_step_ar})`);
      console.log(`🎯 الإجراء: ${action_code}`);
      
      // ✅ البحث بثلاث طرق مرتبة حسب الأولوية:
      // 1. external_shipment_id (= __backendId) - الأكثر أماناً لأنه ما أرسلناه
      // 2. jenni_shipment_id - المعرف الداخلي للزعيم
      // 3. local_serial - الرقم التسلسلي كخيار أخير
      const externalShipmentId = update.external_shipment_id;
      let query = supabase.from("orders").select("*");
      let lookupMethod = "";
      
      if (externalShipmentId && externalShipmentId.length > 0) {
        // ✅ الطريقة الأفضل: البحث بـ __backendId
        query = query.eq("__backendId", externalShipmentId);
        lookupMethod = `__backendId=${externalShipmentId}`;
      } else if (shipment_id) {
        // ✅ البحث بـ jenni_shipment_id (يدعم النص والرقم)
        query = query.eq("jenni_shipment_id", shipment_id);
        lookupMethod = `jenni_shipment_id=${shipment_id}`;
      } else if (shipment_number) {
        // ⚠️ خيار أخير: البحث بـ local_serial
        query = query.eq("local_serial", parseInt(shipment_number) || 0);
        lookupMethod = `local_serial=${shipment_number}`;
      } else {
        console.warn(`⚠️ لا يوجد أي معرف للشحنة، تخطي التحديث`);
        results.push({ 
          external_id: external_id,
          shipment_number, 
          shipment_id, 
          status: "SKIPPED", 
          error: "لا يوجد معرف للشحنة" 
        });
        continue;
      }
      
      console.log(`🔍 البحث باستخدام: ${lookupMethod}`);
      
      const { data: existingOrders, error: findError } = await query;
      
      if (findError || !existingOrders || existingOrders.length === 0) {
        console.warn(`⚠️ لم يتم العثور على الطلب: ${lookupMethod}`);
        results.push({ 
          external_id: external_id,
          shipment_number, 
          shipment_id, 
          status: "NOT_FOUND", 
          error_message: "الطلب غير موجود في النظام" 
        });
        continue;
      }
      
      // ✅ نأخذ أول طلب فقط (يجب أن يكون فريداً إذا استخدمنا shipment_id)
      const order = existingOrders[0];
      
      const newStatus = mapJenniStatusToArabic(current_step || action_code || "");
      
      // ✅ بناء كائن التحديث
      const updateDataObj: any = {
        status: newStatus,
        updated_at: new Date().toISOString(),
      };
      
      // ✅ فقط إذا كانت الملاحظة موجودة وغير فارغة، نضيفها
      if (note && note.trim().length > 0) {
        updateDataObj.admin_notes = note;
        console.log(`📝 إضافة ملاحظة: "${note}"`);
      } else {
        console.log(`📝 لا توجد ملاحظة جديدة، الإبقاء على الملاحظة الحالية`);
      }
      
      const { error: updateError } = await supabase
        .from("orders")
        .update(updateDataObj)
        .eq("__backendId", order.__backendId);
      
      if (updateError) {
        console.error(`❌ فشل تحديث الطلب ${order.__backendId}:`, updateError);
        results.push({ 
          external_id: external_id,
          shipment_number, 
          shipment_id, 
          status: "FAILED", 
          error_message: updateError.message 
        });
      } else {
        console.log(`✅ تم تحديث الطلب ${order.__backendId} إلى: ${newStatus}`);
        results.push({ 
          external_id: external_id,
          shipment_number, 
          shipment_id, 
          status: "SUCCESS",
          new_status: newStatus 
        });
      }
    }
    
    return { success: true, results };
  } catch (error) {
    console.error("❌ خطأ في معالجة تحديث الحالة:", error);
    return { success: false, error: String(error) };
  }
}

// ============== تحويل حالة الزعيم إلى الحالة في التطبيق ==============
function mapJenniStatusToArabic(jenniStatus: string): string {
  if (!jenniStatus) return 'جديد';
  
  const status = jenniStatus.toUpperCase().trim();
  
  const statusMap: { [key: string]: string } = {
    // ✅ واصل (Delivered)
    'DELIVERED': 'واصل',
    'DELIVERED_ARCHIVED': 'واصل',
    'DELIVERED_PRICE_CHANGED': 'واصل',
    'PARTIALLY_DELIVERED': 'واصل',
    'FORCE_DELIVERY': 'واصل',
    'PAYED': 'واصل',
    
    // ✅ راجع (Returned)
    'RTO_WH': 'راجع',
    'RTO_WITH_DA': 'راجع',
    'RTO_ARCHIVED': 'راجع',
    'RTO_CONFIRMED': 'راجع',
    'RTO_FROM_BRANCH': 'راجع',
    'RTO_IN_TRANSIT_WH': 'راجع',
    'RTO_READY_FOR_BRANCH': 'راجع',
    'RTO_WITH_MA': 'راجع',
    'RETURN_APPROVED': 'راجع',
    
    // ✅ مؤجل (Postponed)
    'POSTPONED': 'مؤجل',
    'POSTPONED_CONFIRMED': 'مؤجل',
    'POSTPONEMENT_APPROVED': 'مؤجل',
    
    // ✅ قيد التوصيل (Out for delivery)
    'OFD': 'قيد التوصيل',
    'WITH_MA': 'قيد التوصيل',
    'DELIVERY_REATTEMPT': 'قيد التوصيل',
    
    // ✅ ملغي (Cancelled)
    'CANCELLED': 'ملغي',
    'CANCELED': 'ملغي',
    
    // ✅ جديد (New - default for early stages)
    'IN_SC': 'جديد',
    'NEW_ORDER_TO_PRINT': 'جديد',
    'NEW_ORDER_TO_PICKUP': 'جديد',
    'NEW_WITH_PA': 'جديد',
    'NEW_IN_TRANSIT': 'جديد',
    'PRINT_MANIFEST_DA': 'جديد',
    'BRANCH_PRINT_MANIFEST': 'جديد',
    'TRANSIT': 'جديد',
    'PENDING_DELIVERY_APPROVAL': 'جديد',
    'REJECTED_PRICE_CHANGE': 'جديد',
  };
  
  const mapped = statusMap[status];
  if (mapped) {
    return mapped;
  }
  
  console.warn(`⚠️ حالة غير معروفة من الزعيم: "${jenniStatus}" - استخدام "جديد"`);
  return 'جديد';
}

// ============== جلب الرقم التسلسلي التالي ==============
async function getNextSerialForAgent(agentName: string): Promise<number> {
  try {
    console.log(`📊 جلب الرقم التسلسلي التالي للمندوب: ${agentName}`);
    
    const { data, error } = await supabase
      .from("orders")
      .select("local_serial")
      .eq("agent_name", agentName)
      .order("local_serial", { ascending: false })
      .limit(1);
    
    if (error) {
      console.error("❌ خطأ في جلب الرقم التسلسلي:", error);
      return 1;
    }
    
    let maxSerial = 0;
    if (data && data.length > 0 && data[0].local_serial) {
      maxSerial = data[0].local_serial;
    }
    
    const nextSerial = maxSerial + 1;
    console.log(`📊 الرقم التسلسلي الجديد: ${nextSerial}`);
    return nextSerial;
  } catch (error) {
    console.error("❌ خطأ في جلب الرقم التسلسلي:", error);
    return 1;
  }
}

// ============== الوظيفة الرئيسية ==============
serve(async (req) => {
  // ✅ معالجة OPTIONS (preflight)
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }
  
  try {
    const url = new URL(req.url);
    
    // ✅ نقطة نهاية Webhook: استقبال تحديثات الحالة من نظام الزعيم
    // يدعم المسارات: /update-status أو /v2/push/update-status
    if (req.method === "POST" && (url.pathname.includes("update-status") || url.pathname.endsWith("/update-status"))) {
      console.log("📬 Webhook received at path:", url.pathname);
      
      // ✅ التحقق من توكن Webhook (أمان)
      const expectedToken = Deno.env.get("JENNI_WEBHOOK_TOKEN");
      if (expectedToken) {
        const authHeader = req.headers.get('Authorization');
        const token = authHeader?.replace(/^Bearer\s+/, '');
        if (token !== expectedToken) {
          console.error("❌ توكن Webhook غير صالح");
          return new Response(
            JSON.stringify({ success: false, error: "Unauthorized: Invalid webhook token" }),
            { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders } }
          );
        }
        console.log("✅ تم التحقق من توكن Webhook بنجاح");
      }
      
      try {
        const body = await req.json();
        const result = await handleStatusUpdate(body, req.headers.get('Authorization') || undefined);
        return new Response(
          JSON.stringify(result),
          { 
            status: 200, 
            headers: { "Content-Type": "application/json; charset=utf-8", ...corsHeaders } 
          }
        );
      } catch (webhookError) {
        console.error("❌ خطأ في معالجة Webhook:", webhookError);
        return new Response(
          JSON.stringify({ success: false, error: String(webhookError) }),
          { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
        );
      }
    }
    
    // ✅ Webhook الحذف: Jenni → أنت (DELETE /v2/push/delete-shipment/{external_id})
    // الوثيقة: DELETE YOUR_DOMAIN/v2/push/delete-shipment/{jenniCaseId}
    if (req.method === "DELETE" && url.pathname.includes("delete-shipment")) {
      const pathSegments = url.pathname.split('/').filter(s => s.length > 0);
      const externalId = pathSegments[pathSegments.length - 1];
      
      console.log(`🗑️ Webhook delete received for external_id: ${externalId}`);
      
      // التحقق من التوكن (نفس توكن الـ Webhook)
      const expectedToken = Deno.env.get("JENNI_WEBHOOK_TOKEN");
      if (expectedToken) {
        const authHeader = req.headers.get('Authorization');
        const token = authHeader?.replace(/^Bearer\s+/, '');
        if (token !== expectedToken) {
          console.error("❌ توكن Webhook الحذف غير صالح");
          return new Response(
            JSON.stringify({ ok: false, message: "Unauthorized" }),
            { status: 401, headers: { "Content-Type": "application/json; charset=utf-8", ...corsHeaders } }
          );
        }
        console.log("✅ تم التحقق من توكن Webhook الحذف بنجاح");
      }
      
      if (!externalId || externalId === 'delete-shipment' || externalId === 'send-order-to-jenni') {
        return new Response(
          JSON.stringify({ ok: false, message: "معرف الشحنة مطلوب" }),
          { status: 400, headers: { "Content-Type": "application/json; charset=utf-8", ...corsHeaders } }
        );
      }
      
      try {
        // ✅ الحذف من Supabase باستخدام jenni_shipment_id (= external_id)
        const { error: deleteError, count } = await supabase
          .from("orders")
          .delete()
          .eq("jenni_shipment_id", externalId);
        
        if (deleteError) {
          console.error(`❌ فشل حذف الطلب ${externalId}:`, deleteError);
          return new Response(
            JSON.stringify({ ok: false, message: deleteError.message }),
            { status: 500, headers: { "Content-Type": "application/json; charset=utf-8", ...corsHeaders } }
          );
        }
        
        console.log(`✅ تم حذف الطلب ${externalId} من Supabase (عدد الصفوف: ${count ?? 'غير معروف'})`);
        
        // ✅ Jenni يقبل 200 حتى لو لم يجد الشحنة (404 مقبول)
        return new Response(
          JSON.stringify({ ok: true, external_id: externalId }),
          { status: 200, headers: { "Content-Type": "application/json; charset=utf-8", ...corsHeaders } }
        );
      } catch (deleteErr) {
        console.error("❌ خطأ غير متوقع في Webhook الحذف:", deleteErr);
        return new Response(
          JSON.stringify({ ok: false, message: String(deleteErr) }),
          { status: 500, headers: { "Content-Type": "application/json; charset=utf-8", ...corsHeaders } }
        );
      }
    }
    
    // ✅ نقطة نهاية DELETE القديمة (للاستخدام الداخلي من التطبيق)
    if (req.method === "DELETE") {
      const pathSegments = url.pathname.split('/').filter(s => s.length > 0);
      const shipmentId = pathSegments[pathSegments.length - 1];
      
      console.log(`🗑️ طلب حذف الشحنة: ${shipmentId}`);
      
      if (!shipmentId || shipmentId === 'send-order-to-jenni') {
        return new Response(
          JSON.stringify({ success: false, error: "معرف الشحنة مطلوب" }),
          { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
        );
      }
      
      const result = await deleteShipmentFromJenni(shipmentId);
      
      if (result.success) {
        console.log(`🗑️ حذف الطلب ${shipmentId} من Supabase...`);
        const { error: deleteError } = await supabase
          .from("orders")
          .delete()
          .eq("jenni_shipment_id", parseInt(shipmentId) || shipmentId);
        
        if (deleteError) {
          console.error(`❌ فشل حذف الطلب من Supabase:`, deleteError);
          return new Response(
            JSON.stringify({ success: false, error: `فشل حذف الطلب من Supabase: ${deleteError.message}` }),
            { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
          );
        }
        
        console.log(`✅ تم حذف الطلب ${shipmentId} من Supabase`);
      }
      
      return new Response(
        JSON.stringify(result),
        { 
          status: result.success ? 200 : 500, 
          headers: { "Content-Type": "application/json", ...corsHeaders } 
        }
      );
    }
    
    // ✅ نقطة نهاية POST: إنشاء طلب جديد
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "الطريقة غير مدعومة" }),
        { 
          status: 405, 
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }
    
    const body = await req.json();
    console.log("📥 استلام طلب جديد:", body.customer_name);
    console.log(`📦 المنتج: ${body.product}`);
    console.log(`💰 السعر: ${body.price}`);
    console.log(`🔢 الكمية: ${body.quantity}`);
    
    const { data: productData, error: productError } = await supabase
      .from("products")
      .select("*")
      .eq("name", body.product)
      .single();
    
    if (productError || !productData) {
      console.error("❌ المنتج غير موجود في المخزن:", body.product);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `المنتج "${body.product}" غير موجود في المخزن` 
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }
    
    console.log(`✅ تم العثور على المنتج: ${productData.name} (المتبقي: ${productData.quantity})`);
    
    if (productData.quantity < body.quantity) {
      console.error(`❌ الكمية غير كافية: المطلوب ${body.quantity}، المتوفر ${productData.quantity}`);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `الكمية غير كافية. المتوفر: ${productData.quantity}` 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }
    
    const nextSerial = await getNextSerialForAgent(body.agent_name);
    
    // ✅ إنشاء __backendId فريد
    const backendId = Date.now().toString() + "_" + Math.random().toString(36).substring(2, 8);
    console.log(`🆔 __backendId: ${backendId}`);
    
    console.log("🚀 محاولة إرسال الطلب إلى نظام الزعيم...");
    const result = await sendOrderToJenni(body, backendId);
    
    let jenniShipmentId = null;
    let jenniSuccess = false;
    
    if (result.success) {
      jenniSuccess = true;
      jenniShipmentId = result.data?.shipment_id || null;
      console.log("✅ تم إرسال الطلب إلى نظام الزعيم بنجاح");
      console.log(`📦 jenni_shipment_id: ${jenniShipmentId}`);
    } else {
      console.log("⚠️ فشل الإرسال إلى نظام الزعيم، سيتم الحفظ محلياً فقط");
      console.log(`❌ سبب الفشل: ${result.error}`);
    }
    
    console.log("💾 حفظ الطلب في Supabase...");
    const { data: orderData, error: orderError } = await supabase
      .from("orders")
      .insert({
        __backendId: backendId,
        customer_name: body.customer_name,
        customer_phone: body.customer_phone,
        customer_address: body.customer_address,
        product: body.product,
        product_info: body.product_info,
        quantity: body.quantity,
        price: body.price,
        total: body.total,
        profit: body.profit,
        status: body.status || "جديد",
        agent_name: body.agent_name,
        order_date: body.order_date,
        governorate: body.governorate,
        district: body.district,
        landmark: body.landmark,
        local_serial: nextSerial,
        admin_notes: body.admin_notes,
        jenni_shipment_id: jenniShipmentId,
        jenni_error: result.success ? null : result.error,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        type: "order",
      })
      .select()
      .single();
    
    if (orderError) {
      console.error("❌ خطأ في حفظ الطلب في Supabase:", orderError);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `فشل حفظ الطلب: ${orderError.message}` 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }
    
    console.log(`✅ تم حفظ الطلب في Supabase: ${orderData.__backendId}`);
    
    const newQuantity = productData.quantity - body.quantity;
    console.log(`📊 خصم الكمية: ${productData.quantity} → ${newQuantity}`);
    
    await supabase
      .from("products")
      .update({ 
        quantity: newQuantity,
        updated_at: new Date().toISOString()
      })
      .eq("__backendId", productData.__backendId);
    
    console.log(`✅ تم خصم ${body.quantity} قطعة من ${productData.name}`);
    
    const responseMessage = jenniSuccess 
      ? "تم إرسال الطلب إلى نظام الزعيم وحفظه في Supabase" 
      : "تم حفظ الطلب في Supabase (فشل الاتصال بـ نظام الزعيم)";
    
    return new Response(
      JSON.stringify({
        success: true,
        data: {
          __backendId: orderData.__backendId,
          local_serial: nextSerial,
          jenni_shipment_id: jenniShipmentId
        },
        message: responseMessage
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
        },
      }
    );
  } catch (error) {
    console.error("❌ خطأ غير متوقع:", error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: `خطأ غير متوقع: ${String(error)}` 
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
        },
      }
    );
  }
});