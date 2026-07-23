# infra — Terraform for MLE's GCP/Firebase project

Provisions the Google Cloud project that backs MLE and enables the Firebase
services the app uses. A Firebase project *is* a GCP project with Firebase
enabled on top — so this is plain GCP Terraform.

## What it manages

- The GCP project (`google_project`) with labels and billing linkage.
- Required API enablement (Firestore, Cloud Functions, Auth, FCM, billing, …).
- Firebase enablement on the project.
- The Firestore database (Native mode).
- A billing **budget + alert** (50/90/100% email thresholds) as a cost safety net.

## What it does NOT manage (by design)

- **Firestore rules & indexes** → owned by the Firebase CLI
  (`firestore.rules` / `firestore.indexes.json` at the repo root, `firebase deploy`).
  Keeps rule iteration fast without a `terraform apply` each time.
- **Cloud Functions code** → deployed by the Firebase CLI (`functions/`).

Terraform owns the *project and platform*; the Firebase CLI owns *app config*.

## Layout

| File | Purpose |
|------|---------|
| `versions.tf`   | Provider + Terraform version constraints, backend. |
| `variables.tf`  | Input variables. |
| `project.tf`    | GCP project + API enablement. |
| `firebase.tf`   | Firebase + Firestore database. |
| `budget.tf`     | Billing budget + alert notification channels. |
| `outputs.tf`    | Project id/number, Firestore info, enabled APIs. |
| `*.tfvars.example` | Copy to `dev.tfvars` / `prod.tfvars` and fill in. |

## Usage

```sh
cd infra
cp dev.tfvars.example dev.tfvars     # then edit

terraform init
terraform fmt -check                 # style
terraform validate                   # config validity — no cloud/billing needed
terraform plan  -var-file=dev.tfvars # preview — needs auth; billing optional
terraform apply -var-file=dev.tfvars # create — needs a billing_account set
```

## Cost & billing

- `validate` and (billing-less) `plan` cost nothing and need no card.
- `apply` needs a `billing_account` (Firestore/Functions require billing). The
  Firebase/GCP free tier covers a small app; the budget alert emails you long
  before any real charge.

## State

State is **git-ignored** and local by default. For a shared setup, switch to a
GCS backend (commented block in `versions.tf`).

## Environments

`dev.tfvars` and `prod.tfvars` drive separate projects (`mle-pickup-dev` /
`mle-pickup-prod`) from the same config. Use separate state per environment
(separate local dirs or GCS prefixes).
