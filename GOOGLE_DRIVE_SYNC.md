# Google Drive Integration Specification (Private Sync™)

## 1. OAuth Scope Restriction
- Scope: `https://www.googleapis.com/auth/drive.appdata`
- Access limited strictly to PaisaPilot's private app data folder in the user's personal Drive.

## 2. Zero Server Trust Model
No intermediate PaisaPilot servers touch the synchronization payload. The Flutter client communicates directly with Google's HTTPS REST API endpoint via TLS 1.3.

## 3. Upload & Download Protocols
- Files uploaded as `backup.ppbackup`.
- Uploads and downloads stream encrypted byte buffers.
