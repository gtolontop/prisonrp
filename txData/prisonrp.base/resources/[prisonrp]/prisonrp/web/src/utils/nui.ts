/**
 * NUI Communication Utilities
 * Handles all communication between React UI and FiveM client/server
 */

import type { ReactToLuaEvents, NUIResponse } from '@/types/nui';

/**
 * Check if running in FiveM (production) or browser (dev mode)
 */
export const isEnvBrowser = (): boolean => !(window as any).invokeNative;

/**
 * Send event to FiveM client
 * @param event Event name
 * @param data Event data
 * @returns Promise with server response
 */
export async function fetchNUI<T = any>(
  event: string,
  data?: any
): Promise<NUIResponse<T>> {
  // In dev mode (browser), return mock success
  if (isEnvBrowser()) {
    console.log(`[DEV] NUI Event: ${event}`, data);
    return {
      success: true,
      data: undefined as any,
    };
  }

  // Production: send to FiveM
  try {
    const response = await fetch(`https://prisonrp/${event}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data || {}),
    });

    const result = await response.json();
    return result as NUIResponse<T>;
  } catch (error) {
    console.error(`[NUI] Error sending event ${event}:`, error);
    return {
      success: false,
      error: 'Failed to communicate with game',
    };
  }
}

/**
 * Type-safe NUI event sender
 */
export async function sendNUIEvent<K extends keyof ReactToLuaEvents>(
  event: K,
  data: ReactToLuaEvents[K]
): Promise<NUIResponse> {
  return fetchNUI(event as string, data);
}

/**
 * Register listener for events FROM Lua TO React
 */
export function onNUIEvent<T = any>(
  event: string,
  callback: (data: T) => void
): () => void {
  const handler = (e: MessageEvent) => {
    if (e.data.type === event) {
      callback(e.data.data);
    }
  };

  window.addEventListener('message', handler);

  // Return cleanup function
  return () => window.removeEventListener('message', handler);
}

/**
 * Register ESC key handler (close UI)
 */
export function registerEscapeHandler(callback: () => void): () => void {
  const handler = (e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      e.preventDefault();
      callback();
    }
  };

  window.addEventListener('keydown', handler);
  return () => window.removeEventListener('keydown', handler);
}

/**
 * Debug helper: simulate NUI event in dev mode
 */
export function debugNUIEvent<T = any>(event: string, data: T): void {
  if (isEnvBrowser()) {
    window.postMessage(
      {
        type: event,
        data: data,
      },
      '*'
    );
  }
}

/**
 * Batch NUI events (send multiple at once)
 * Useful for complex operations like moving multiple items
 */
export async function batchNUIEvents<K extends keyof ReactToLuaEvents>(
  events: Array<{ event: K; data: ReactToLuaEvents[K] }>
): Promise<NUIResponse[]> {
  if (isEnvBrowser()) {
    console.log('[DEV] Batch NUI Events:', events);
    return events.map(() => ({ success: true }));
  }

  // In production, send all events
  const promises = events.map(({ event, data }) =>
    sendNUIEvent(event, data)
  );

  return Promise.all(promises);
}

/**
 * Request full data sync from server
 */
export async function requestDataSync(): Promise<NUIResponse> {
  return sendNUIEvent('requestSync', {});
}

/**
 * Close current UI
 */
export async function closeUI(): Promise<NUIResponse> {
  return sendNUIEvent('closeUI', {});
}
