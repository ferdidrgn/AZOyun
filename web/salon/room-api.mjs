const jsonContentType = /(?:^|;)\s*application\/json(?:\s*;|$)/i;

export function normalizeApiOrigin(value, pageProtocol = "https:") {
  const url = new URL(value);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password ||
      (pageProtocol === 'https:' && url.protocol !== 'https:') ||
      url.pathname !== '/' || url.search || url.hash) {
    throw new Error('Geçerli bir HTTPS sunucu adresi gir.');
  }
  return url.origin;
}

export function apiCandidates({ pageOrigin, configuredOrigin = '', discoveredOrigin = '', explicitOrigin = '' }) {
  const values = [explicitOrigin, configuredOrigin, discoveredOrigin, pageOrigin]
    .filter(Boolean)
    .map((value) => normalizeApiOrigin(value, new URL(pageOrigin).protocol));
  return [...new Set(values)];
}

export async function discoverApiOrigin(fetchImpl, pageOrigin) {
  try {
    const response = await fetchImpl(new URL('/salon/family-api.json', pageOrigin), {
      cache: 'no-store',
      headers: { Accept: 'application/json' },
    });
    if (!response.ok || !jsonContentType.test(response.headers.get('content-type') || '')) return '';
    const data = await response.json();
    return data?.origin ? normalizeApiOrigin(data.origin, new URL(pageOrigin).protocol) : '';
  } catch {
    return '';
  }
}

export async function requestRoomApi({ fetchImpl, origins, path, data, auth, timeoutMs = 7000 }) {
  let lastFailure;
  for (const origin of origins) {
    try {
      const signal = globalThis.AbortSignal?.timeout?.(timeoutMs);
      const response = await fetchImpl(origin + '/api/family/rooms' + path, {
        method: data ? 'POST' : 'GET',
        headers: {
          ...(auth && { Authorization: 'Bearer ' + auth }),
          ...(data && { 'Content-Type': 'application/json' }),
          Accept: 'application/json',
        },
        body: data ? JSON.stringify(data) : undefined,
        cache: 'no-store',
        ...(signal && { signal }),
      });
      if (!jsonContentType.test(response.headers.get('content-type') || '')) {
        lastFailure = new Error('API JSON yanıtı vermedi.');
        continue;
      }
      const result = await response.json();
      if (!response.ok) throw Object.assign(new Error(result.error || 'Masa açılamadı.'), {
        status: response.status,
      });
      return { origin, result };
    } catch (error) {
      if (error?.status) throw error;
      lastFailure = error;
    }
  }
  throw new Error(lastFailure?.message === 'API JSON yanıtı vermedi.'
    ? 'Firebase Aile Masası API yanıt vermedi. Yayın yapılandırmasını kontrol et.'
    : 'Firebase oda hizmetine ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.');
}
