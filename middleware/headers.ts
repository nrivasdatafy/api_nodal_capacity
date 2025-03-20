// Validate access to our internal or external API
export const HEADER_NAME_API_AUTH = 'X-Auth-Token';

// Handled internally by the API, never read but instead always written (aka write-only)
export const HEADER_NAME_API_VERSION = 'X-API-Version';
export const HEADER_NAME_API_PROD_MODE = 'X-API-Prod-Mode';
