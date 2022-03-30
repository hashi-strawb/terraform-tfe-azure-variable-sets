#!/bin/bash

set -e

# No validation, as this is a workaround until https://github.com/hashicorp/terraform-provider-tfe/issues/391 exists

INPUT=$(cat -)
# e.g.
#{
#  "ARM_SUBSCRIPTION_ID": "",
#  "ARM_CLIENT_ID": "",
#  "ARM_CLIENT_SECRET": "",
#  "ARM_TENANT_ID": "",
#  "ARM_DISPLAY_NAME": ""
#}

if [[ -z "${TFC_ORG}" ]]; then
	echo "Missing Env Var: TFC_ORG"
	exit 1
fi

if [[ -z "${TFC_VARSET_ID}" ]]; then
	echo "Missing Env Var: TFC_VARSET_ID"
	exit 1
fi





# TODO: check if this file exists
# If not, do a `terraform login`
TFC_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')



# Convert input JSON to varset syntax
# [
#   {
#    "type": "vars",
#     "attributes": {
#       "key": "ARM_SUBSCRIPTION_ID",
#       "value": "${ARM_SUBSCRIPTION_ID}",
#       "category": "env"
#     }
#   }, ...
# ]
VARSET_VARIABLES=$(echo $INPUT | jq 'to_entries[] |
{
	"type": "vars",
	"attributes": {
		"key": .key,
		"value": .value,
		"category": "env",
		"sensitive": true
	}
}' | jq -s .)


# TODO: check for any SECRET variables, and mark as sensitive
# For now, we mark everything as sensitive

json_payload=$(cat <<EOF
{
  "data": {
	"relationships": {
	  "vars": {
		"data": ${VARSET_VARIABLES}
	  }
	}
  }
}
EOF
)


echo ${json_payload} | jq .




varset_response=$(curl \
  --header "Authorization: Bearer $TFC_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request PUT \
  --data "${json_payload}" \
  https://app.terraform.io/api/v2/varsets/${TFC_VARSET_ID})
echo ${varset_response} | jq .

# VARSET_ID=$(echo ${varset_response} | jq -r .data.id)
# echo ID: ${VARSET_ID}






# # Apply Varset to workspace(s)
# # https://www.terraform.io/cloud-docs/api-docs/variable-sets#apply-variable-set-to-workspaces
# 
# # Convert list of workspaces to payload in format:
# # {
# #   "data": [
# #     {
# #       "type": "workspaces",
# #       "id": "ws-YwfuBJZkdai4xj9w"
# #     }, ...
# #   ]
# # }
# 
# data_array=$(echo ${WORKSPACE_IDS} | jq -Rc 'split(",") | to_entries[] |
# {
# 	"type": "workspaces",
# 	"id": .value
# }' | jq -s .)
# 
# 
# json_payload=$(cat << EOF
# {
# 	"data" : ${data_array}
# }
# EOF
# )
# echo ${json_payload} | jq .
# 
# curl \
#   --header "Authorization: Bearer $TFC_TOKEN" \
#   --header "Content-Type: application/vnd.api+json" \
#   --request POST \
#   --data "${json_payload}" \
#   https://app.terraform.io/api/v2/varsets/${VARSET_ID}/relationships/workspaces
