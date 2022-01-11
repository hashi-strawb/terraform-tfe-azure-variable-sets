#!/bin/bash

# Based on
# https://docs.microsoft.com/en-gb/cli/azure/create-an-azure-service-principal-azure-cli
# And internal HashiCorp docs
# https://hashicorp.atlassian.net/wiki/spaces/SE/pages/310509843/Microsoft+Azure

if ! command -v jq &> /dev/null
then
	>&2 echo "jq could not be found. Please install: https://stedolan.github.io/jq/"
	exit 1
fi

if ! command -v az &> /dev/null
then
	>&2 echo "az could not be found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
	exit 1
fi

if [[ -z "${ARM_SUBSCRIPTION_ID}" ]]; then
	echo "Missing Env Var: ARM_SUBSCRIPTION_ID"
	exit 1
fi
if [[ -z "${ARM_DISPLAY_NAME}" ]]; then
	echo "Missing Env Var: ARM_DISPLAY_NAME"
	exit 1
fi

# This will trigger a browser-based oauth workflow
# unless we are already logged in
# TODO: optionally force login?
if [[ $(az account list | jq length) == "0" ]]; then
	az login
fi


# TODO: if env var not set, get by name...
# export ARM_SUBSCRIPTION_ID=$(az account list | jq -r '.[] | select(.name=="Team Solutions Engineers") | .id')

az account set --subscription="${ARM_SUBSCRIPTION_ID}"

# Create Servivce Principal
read ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_TENANT_ID ARM_DISPLAY_NAME < <(echo $(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${ARM_SUBSCRIPTION_ID}" --name="${ARM_DISPLAY_NAME}" | jq -r '.appId, .password, .tenant, .displayName'))

cat << EOF
{
	"ARM_SUBSCRIPTION_ID" : "${ARM_SUBSCRIPTION_ID}",
	"ARM_CLIENT_ID"       : "${ARM_CLIENT_ID}",
	"ARM_CLIENT_SECRET"   : "${ARM_CLIENT_SECRET}",
	"ARM_TENANT_ID"       : "${ARM_TENANT_ID}",
	"ARM_DISPLAY_NAME"    : "${ARM_DISPLAY_NAME}"
}
EOF
