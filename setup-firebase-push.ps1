# One-time setup: let the Cloud Run backend send Firebase push notifications.
#
# Keyless: the backend (NotificationService.firebaseApp) falls back to Application
# Default Credentials when FIREBASE_SERVICE_ACCOUNT_JSON / _FILE are not set. On
# Cloud Run, ADC is the service's own runtime service account, so we only grant that
# account permission to send FCM messages. No JSON key is uploaded anywhere.
#
# Run in PowerShell (Google Cloud SDK installed, signed in as a project Owner):
#   gcloud auth login
#   powershell -ExecutionPolicy Bypass -File .\setup-firebase-push.ps1

param(
    [string]$Project = "office-central-erp",
    [string]$Region  = "asia-south1",
    [string]$Service = "pinventory"
)

function Run([string]$what, [scriptblock]$cmd) {
    Write-Host "`n>> $what" -ForegroundColor Cyan
    $out = & $cmd
    if ($LASTEXITCODE -ne 0) { Write-Host "FAILED: $what" -ForegroundColor Red; exit 1 }
    return $out
}

# 1. Find the service account the Cloud Run service runs as.
$sa = Run "Reading Cloud Run runtime service account" {
    gcloud run services describe $Service --project $Project --region $Region `
        --format "value(spec.template.spec.serviceAccountName)"
}
if ([string]::IsNullOrWhiteSpace($sa)) {
    $num = Run "Reading project number" { gcloud projects describe $Project --format "value(projectNumber)" }
    $sa = "$num-compute@developer.gserviceaccount.com"   # Cloud Run default
}
$sa = $sa.Trim()
Write-Host "Runtime service account: $sa"

# 2. Make sure the FCM HTTP v1 API is enabled.
Run "Enabling Firebase Cloud Messaging API" {
    gcloud services enable fcm.googleapis.com --project $Project
} | Out-Null

# 3. Allow that account to send FCM messages (least privilege for sending).
Run "Granting roles/firebasecloudmessaging.admin to $sa" {
    gcloud projects add-iam-policy-binding $Project `
        --member "serviceAccount:$sa" --role "roles/firebasecloudmessaging.admin" `
        --condition=None --format "none"
} | Out-Null

# 4. Pin the Firebase project ID (rolls out a new revision with the same image).
Run "Setting FIREBASE_PROJECT_ID on $Service" {
    gcloud run services update $Service --project $Project --region $Region `
        --update-env-vars "FIREBASE_PROJECT_ID=$Project"
} | Out-Null

# 5. Warn if an old key variable is set: it takes precedence over the keyless path.
$envs = gcloud run services describe $Service --project $Project --region $Region `
    --format "value(spec.template.spec.containers[0].env[].name)"
if ($envs -match "FIREBASE_SERVICE_ACCOUNT_(JSON|FILE)") {
    Write-Host "`nNOTE: FIREBASE_SERVICE_ACCOUNT_JSON/FILE is set on the service and overrides keyless auth." -ForegroundColor Yellow
    Write-Host "      If pushes fail with a credential error, remove it in Cloud Run > Edit & deploy > Variables." -ForegroundColor Yellow
}

Write-Host "`nDone. Cloud Run can now send FCM pushes as $sa (no key file used)." -ForegroundColor Green
